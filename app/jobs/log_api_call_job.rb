# frozen_string_literal: true

# Records each API call in Elasticsearch for Kibana to chart. Runs as a job so a slow or unavailable Elasticsearch
# never holds up the API's response.
#
# Documents match Planning Alerts' pa-api-* indices (same field names, monthly indices) so both sites' calls can be
# charted together, with site telling them apart. Only the user id is sent, not their name or email (see #1872).
class LogApiCallJob < ApplicationJob
  queue_as :default

  # Rides out a few hours of Elasticsearch being unavailable, then gives up. Delayed Job's own default of 25 tries
  # would keep every call of an outage in the queue for weeks.
  retry_on StandardError, attempts: 10, wait: :polynomially_longer do |_job, error|
    Sentry.capture_exception(error)
  end

  def self.log(request, user:)
    return unless Rails.configuration.x.log_api_calls_to_elasticsearch

    perform_later(
      user_id: user.id,
      endpoint: "#{request.path_parameters[:controller].delete_prefix('api/v1/')}##{request.path_parameters[:action]}",
      query: ApiStatistic.path_without_key(request),
      params: logged_params(request),
      ip_address: request.remote_ip,
      user_agent: request.headers["User-Agent"],
      time: Time.current
    )
  end

  # The parameters the API reads. Each becomes a field in the index, so other names (still in query) are left out:
  # made-up ones could fill Elasticsearch's limit of 1000 fields, and ActiveJob refuses names starting "_aj_".
  LOGGED_PARAMS = %w[id format start_date end_date house ai_assisted].freeze

  # Values are logged as text, so an array or hash sent where others sent a string can't clash with the field's type
  # in the index and stop the document being stored
  def self.logged_params(request)
    # Path parameters win, as they do in Rails' params, so a query string's id can't misreport which record was served
    request.query_parameters.merge(request.path_parameters).stringify_keys.slice(*LOGGED_PARAMS)
           .transform_values { |value| value.is_a?(String) ? value : value.to_json }
  end
  private_class_method :logged_params

  # Fixed field types for every index. Left to itself, Elasticsearch guesses each field's type from a month's first
  # call, so a field such as start_date could be a date one month and text the next. Kibana then can't chart it across
  # months, and merging months into one index rejects the calls that don't match (as with Planning Alerts' pa-api-*).
  # See https://www.elastic.co/guide/en/elasticsearch/reference/7.17/dynamic-templates.html
  MAPPINGS = {
    date_detection: false,
    dynamic_templates: [
      { strings_as_keywords: { match_mapping_type: "string", mapping: { type: "keyword", ignore_above: 1024 } } }
    ],
    properties: { query_time: { type: "date" }, user: { properties: { id: { type: "long" } } } }
  }.freeze

  def perform(user_id:, endpoint:, query:, params:, ip_address:, user_agent:, time:)
    # Underscores, unlike Planning Alerts' pa-api-*, so the theyvoteforyou Elasticsearch role's tvfy_* covers it
    index = "tvfy_api_#{Rails.env}_#{time.utc.strftime('%Y.%m')}"
    create_index(index)
    Searchkick.client.index(
      index: index,
      # A retry after a timeout that Elasticsearch had in fact stored overwrites it, rather than counting the call twice
      id: job_id,
      body: {
        site: "theyvoteforyou", user: { id: user_id }, endpoint: endpoint, query: query, params: params,
        ip_address: ip_address, user_agent: user_agent, query_time: time.utc
      }
    )
  end

  private

  # Remembered in the cache so it's tried once a month rather than on every call
  def create_index(index)
    Rails.cache.fetch("log_api_call_job/created/#{index}", expires_in: 1.day) do
      Searchkick.client.indices.create(index: index, body: { settings: SEARCHKICK_INDEX_SETTINGS, mappings: MAPPINGS })
      true
    rescue Elasticsearch::Transport::Transport::Errors::BadRequest => e
      raise unless e.message.include?("resource_already_exists_exception")

      true
    end
  end
end

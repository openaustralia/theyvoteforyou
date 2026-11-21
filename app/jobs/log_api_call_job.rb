# frozen_string_literal: true

# Copies an api_statistics row to Elasticsearch for Kibana to chart. Runs as a job so a slow or unavailable
# Elasticsearch never holds up the API's response.
#
# The row is the source of truth: each document is built from it alone and stored under an id taken from it, so
# the same call can be sent again (live, or by a batched upload of past rows, #1916) without being counted twice.
#
# Documents match Planning Alerts' pa-api-* indices (same field names, monthly indices) so both sites' calls can be
# charted together, with site telling them apart. Only the user id is sent, not their name or email (see #1872).
class LogApiCallJob < ApplicationJob
  queue_as :default

  # Rides out a few hours of Elasticsearch being unavailable, then gives up. Delayed Job's own default of 25 tries
  # would keep every call of an outage in the queue for weeks. A call given up on is still in api_statistics, so it
  # can be sent again before that month is trimmed (#1874).
  retry_on StandardError, attempts: 10, wait: :polynomially_longer do |_job, error|
    Sentry.capture_exception(error)
  end

  def self.log(api_statistic)
    return unless Rails.configuration.x.log_api_calls_to_elasticsearch

    perform_later(api_statistic.id)
  end

  # The parameters the API reads. Each becomes a field in the index, so other names (still in query) are left out:
  # made-up ones could fill Elasticsearch's limit of 1000 fields.
  LOGGED_PARAMS = %w[id format start_date end_date house ai_assisted].freeze

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

  # Underscores, unlike Planning Alerts' pa-api-*, so the theyvoteforyou Elasticsearch role's tvfy_* covers it
  def self.index_name(time)
    "tvfy_api_#{Rails.env}_#{time.utc.strftime('%Y.%m')}"
  end

  def self.document_id(api_statistic)
    "api_statistics-#{api_statistic.id}"
  end

  def self.document(api_statistic)
    query = ApiStatistic.path_without_key(api_statistic.query.to_s)
    path, query_string = query.split("?", 2)
    route = api_route(path)
    {
      site: "theyvoteforyou", user: { id: api_statistic.user_id },
      endpoint: route ? "#{route[:controller].delete_prefix('api/v1/')}##{route[:action]}" : "unknown",
      query: query,
      params: logged_params(query_string, route || {}),
      ip_address: api_statistic.ip_address, user_agent: api_statistic.user_agent,
      query_time: api_statistic.created_at.utc
    }
  end

  # Matches the path as Rails did when serving it, so a trailing .json gives format. Older rows may hold paths the
  # current routes no longer serve, which still count as calls, under endpoint "unknown".
  def self.api_route(path)
    route = Rails.application.routes.recognize_path(path.to_s)
    route if route[:controller].start_with?("api/v1/")
  rescue ActionController::RoutingError
    nil
  end
  private_class_method :api_route

  # Values are logged as text, so an array or hash sent where others sent a string can't clash with the field's type
  # in the index and stop the document being stored
  def self.logged_params(query_string, route)
    # Path parameters win, as they do in Rails' params, so a query string's id can't misreport which record was served
    query_params(query_string).merge(route.stringify_keys).slice(*LOGGED_PARAMS)
                              .transform_values { |value| value.is_a?(String) ? value : value.to_json }
  end
  private_class_method :logged_params

  # Rails parsed these once to serve the call, but a stored row is checked again rather than trusted, so one bad row
  # can't stop a batched upload
  def self.query_params(query_string)
    Rack::Utils.parse_nested_query(query_string)
  rescue Rack::Utils::ParameterTypeError, Rack::Utils::InvalidParameterError
    {}
  end
  private_class_method :query_params

  def perform(api_statistic_id)
    # Gone if its month was trimmed (#1874) while this waited to be retried
    api_statistic = ApiStatistic.find_by(id: api_statistic_id)
    return unless api_statistic

    index = self.class.index_name(api_statistic.created_at)
    create_index(index)
    Searchkick.client.index(
      index: index, id: self.class.document_id(api_statistic), body: self.class.document(api_statistic)
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

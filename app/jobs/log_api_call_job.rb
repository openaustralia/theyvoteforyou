# frozen_string_literal: true

# Records each API call in Elasticsearch for Kibana to chart. Runs as a job so a slow or unavailable Elasticsearch
# never holds up the API's response.
#
# Documents match Planning Alerts' pa-api-* indices (same field names, monthly indices) so both sites' calls can be
# charted together, with site telling them apart. Only the user id is sent, not their name or email (see #1872).
class LogApiCallJob < ApplicationJob
  queue_as :default

  def self.log(request, user:)
    return unless Rails.configuration.x.log_api_calls_to_elasticsearch

    perform_later(
      user_id: user.id,
      endpoint: "#{request.path_parameters[:controller].delete_prefix('api/v1/')}##{request.path_parameters[:action]}",
      query: ApiStatistic.path_without_key(request),
      params: params_without_key(request),
      ip_address: request.remote_ip,
      user_agent: request.headers["User-Agent"],
      time: Time.current
    )
  end

  # Values are logged as text, so an array or hash sent where others sent a string can't clash with the field's type
  # in the index and stop the document being stored
  def self.params_without_key(request)
    request.path_parameters.except(:controller, :action).merge(request.query_parameters.except("key"))
           .to_h { |name, value| [name.to_s, value.is_a?(String) ? value : value.to_json] }
  end
  private_class_method :params_without_key

  def perform(user_id:, endpoint:, query:, params:, ip_address:, user_agent:, time:)
    Searchkick.client.index(
      index: "tvfy-api-#{Rails.env}-#{time.utc.strftime('%Y.%m')}",
      body: {
        site: "theyvoteforyou", user: { id: user_id }, endpoint: endpoint, query: query, params: params,
        ip_address: ip_address, user_agent: user_agent, query_time: time.utc
      }
    )
  end
end

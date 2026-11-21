# frozen_string_literal: true

# Copies an api_statistics row to Elasticsearch for Kibana to chart (see ApiLog). Runs as a job so a slow or
# unavailable Elasticsearch never holds up the API's response.
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

  def perform(api_statistic_id)
    # Gone if its month was trimmed (#1874) while this waited to be retried
    api_statistic = ApiStatistic.find_by(id: api_statistic_id)
    return unless api_statistic

    index = ApiLog::Index.monthly_name(api_statistic.created_at)
    ApiLog::Index.create(index)
    Searchkick.client.index(
      index: index, id: ApiLog::Document.id(api_statistic), body: ApiLog::Document.build(api_statistic)
    )
  end
end

# frozen_string_literal: true

module ApiLog
  # The Elasticsearch document for one api_statistics row. Built from the row alone and stored under an id taken from
  # it, so a call sent again (live, or by a batched upload of past rows, #1916) replaces itself rather than being
  # counted twice.
  #
  # Fields match Planning Alerts' pa-api-* indices so both sites' calls can be charted together, with site telling
  # them apart. Only the user id is sent, not their name or email (see #1872).
  module Document
    # The parameters the API reads. Each becomes a field in the index, so other names (still in query) are left out:
    # made-up ones could fill Elasticsearch's limit of 1000 fields.
    LOGGED_PARAMS = %w[id format start_date end_date house ai_assisted].freeze

    def self.id(api_statistic)
      "api_statistics-#{api_statistic.id}"
    end

    def self.build(api_statistic)
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

    # Values are logged as text, so an array or hash sent where others sent a string can't clash with the field's
    # type in the index and stop the document being stored
    def self.logged_params(query_string, route)
      # Path parameters win, as they do in Rails' params, so a query string's id can't misreport which record was
      # served
      query_params(query_string).merge(route.stringify_keys).slice(*LOGGED_PARAMS)
                                .transform_values { |value| value.is_a?(String) ? value : value.to_json }
    end
    private_class_method :logged_params

    # Rails parsed these once to serve the call, but a stored row is checked again rather than trusted, so one bad
    # row can't stop a batched upload
    def self.query_params(query_string)
      Rack::Utils.parse_nested_query(query_string)
    rescue Rack::Utils::ParameterTypeError, Rack::Utils::InvalidParameterError
      {}
    end
    private_class_method :query_params
  end
end

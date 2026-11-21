# frozen_string_literal: true

module ApiLog
  # Where API calls are stored in Elasticsearch, for Kibana to chart. Each month's calls go in a monthly index, and
  # completed years are combined into one yearly index (#1917). The pattern tvfy_api_<env>_* matches both, so
  # Kibana's data views don't change when a year is combined.
  #
  # Names use underscores, unlike Planning Alerts' pa-api-*, so the theyvoteforyou Elasticsearch role's tvfy_*
  # covers them.
  module Index
    # Fixed field types for every index. Left to itself, Elasticsearch guesses each field's type from a month's first
    # call, so a field such as start_date could be a date one month and text the next. Kibana then can't chart it
    # across months, and combining months into one index rejects the calls that don't match (as with Planning Alerts'
    # pa-api-*). See https://www.elastic.co/guide/en/elasticsearch/reference/7.17/dynamic-templates.html
    MAPPINGS = {
      date_detection: false,
      dynamic_templates: [
        { strings_as_keywords: { match_mapping_type: "string", mapping: { type: "keyword", ignore_above: 1024 } } }
      ],
      properties: { query_time: { type: "date" }, user: { properties: { id: { type: "long" } } } }
    }.freeze

    def self.monthly_name(time)
      "tvfy_api_#{Rails.env}_#{time.utc.strftime('%Y.%m')}"
    end

    def self.yearly_name(year)
      "tvfy_api_#{Rails.env}_#{year}"
    end

    # Remembered in the cache so the job tries it once a month rather than on every call. An index deleted by hand
    # is still remembered for up to a day, so delete its cache entry too, or the next call recreates it without
    # MAPPINGS.
    def self.create(name)
      Rails.cache.fetch("api_log/index/created/#{name}", expires_in: 1.day) do
        Searchkick.client.indices.create(index: name, body: { settings: SEARCHKICK_INDEX_SETTINGS, mappings: MAPPINGS })
        true
      rescue Elasticsearch::Transport::Transport::Errors::BadRequest => e
        raise unless e.message.include?("resource_already_exists_exception")

        true
      end
    end

    def self.exists?(name)
      Searchkick.client.indices.exists?(index: name)
    end

    # Calls made in [from, to) that are stored in the named index, or 0 if it doesn't exist
    def self.count(name, from:, to:)
      Searchkick.client.count(
        index: name, ignore_unavailable: true,
        body: { query: { range: { query_time: { gte: from.utc.iso8601, lt: to.utc.iso8601 } } } }
      )["count"]
    end
  end
end

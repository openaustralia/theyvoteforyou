# frozen_string_literal: true

# To reduce log noise
Ethon.logger = Logger.new(nil)

ENV["ELASTICSEARCH_URL"] = Rails.application.credentials.elasticsearch.url if Rails.application.credentials.elasticsearch&.url

# A single-node dev/test cluster can never satisfy a replica, which otherwise leaves
# cluster health permanently yellow. Production/staging are left to Elasticsearch's
# own default (currently 1) by passing no override.
SEARCHKICK_INDEX_SETTINGS = (Rails.env.local? ? { number_of_replicas: 0 } : {}).freeze

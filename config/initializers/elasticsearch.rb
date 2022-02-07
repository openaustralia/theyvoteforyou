# frozen_string_literal: true

# To reduce log noise
Ethon.logger = Logger.new(nil)

ENV["ELASTICSEARCH_URL"] = Settings.elasticsearch_url if Settings.elasticsearch_url

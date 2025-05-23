# frozen_string_literal: true

# To reduce log noise
Ethon.logger = Logger.new(nil)

ENV["ELASTICSEARCH_URL"] = Rails.application.credentials.elasticsearch.url if Rails.application.credentials.elasticsearch&.url

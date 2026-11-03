# frozen_string_literal: true

# To reduce log noise
Ethon.logger = Logger.new(nil)

# Lets a moved dev/test Elasticsearch container (see "Port clashes" in AGENTS.md) be found without spelling out the URL
elasticsearch_port = ENV.fetch("ELASTICSEARCH_PORT", nil)
ENV["ELASTICSEARCH_URL"] ||= "http://localhost:#{elasticsearch_port}" if elasticsearch_port
ENV["ELASTICSEARCH_URL"] = Rails.application.credentials.elasticsearch.url if Rails.application.credentials.elasticsearch&.url

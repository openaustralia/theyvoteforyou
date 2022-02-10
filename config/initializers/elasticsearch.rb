# frozen_string_literal: true

# To reduce log noise
Ethon.logger = Logger.new(nil)

ENV["ELASTICSEARCH_URL"] = Rails.application.secrets.elasticsearch_url if Rails.application.secrets.elasticsearch_url

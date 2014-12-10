# Suggested for best performance by Searchkick https://github.com/ankane/searchkick#performance
require "typhoeus/adapters/faraday"
Ethon.logger = Logger.new("/dev/null")

ENV["ELASTICSEARCH_URL"] = Settings.elasticsearch_url if Settings.elasticsearch_url

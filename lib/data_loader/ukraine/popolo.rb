require "open-uri"
require "json"

module DataLoader
  module Ukraine
    class Popolo
      def self.load(url)
        Rails.logger.info "Loading Ukraine Popolo data from #{url}..."
        data = JSON.parse(open(url).read)
        raise "No loadable data found" unless data["persons"] || data["vote_events"]

        data
      end
    end
  end
end

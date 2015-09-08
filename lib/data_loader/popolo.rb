require "open-uri"
require "json"

module DataLoader
  class Popolo
    def self.load!(url)
      Rails.logger.info "Loading Popolo data from #{url}..."
      data = JSON.parse(open(url).read)

      # Load people data...
      people = data["persons"]
      Rails.logger.info "Loading #{people.count} people..."
      people.each do |p|
        person = Person.find_or_initialize_by(id: p["id"][/\d+/])
        person.large_image_url = p["image"]
        person.save!
      end
    end
  end
end

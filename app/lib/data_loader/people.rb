# frozen_string_literal: true

require "mechanize"

module DataLoader
  class People
    def self.member_to_person
      @member_to_person ||= load_people
    end

    # Try to load any people images that are currently missing
    def self.load_missing_images!
      Person.where(small_image_url: nil).find_each do |person|
        Rails.logger.info "Checking small photo for person #{person.id}..."
        url = "https://www.openaustralia.org.au/images/mps/#{person.id}.jpg"
        person.update(small_image_url: url) if CheckResourceExists.call(url)
      end
      Person.where(large_image_url: nil).find_each do |person|
        Rails.logger.info "Checking large photo for person #{person.id}..."
        url = "https://www.openaustralia.org.au/images/mpsL/#{person.id}.jpg"
        person.update(large_image_url: url) if CheckResourceExists.call(url)
      end
    end

    # people.xml
    def self.load_people
      agent = Mechanize.new
      people_xml = agent.get "#{Settings.xml_data_base_url}members/people.xml"
      member_to_person = {}
      people_xml.search(:person).each do |person|
        person.search(:office).each do |office|
          member_to_person[office[:id]] = person[:id]
        end
      end
      member_to_person
    end
  end
end

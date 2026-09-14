# frozen_string_literal: true

require "mechanize"

module DataLoader
  class People
    def self.member_to_person
      @member_to_person ||= load_people
    end

    # Directory on openaustralia.org.au for each portrait size
    SOURCE_DIRECTORIES = { small: "mps", large: "mpsL", extra_large: "mpsXL" }.freeze

    # Try to load any people images that are currently missing
    def self.load_missing_images!
      SOURCE_DIRECTORIES.each do |size, directory|
        Person.where("#{size}_image_url": nil).find_each do |person|
          Rails.logger.info "Checking #{size} photo for person #{person.id}..."
          url = "https://www.openaustralia.org.au/images/#{directory}/#{person.id}.jpg"
          next unless CheckResourceExists.call(url)

          person.update("#{size}_image_url": url)
          PortraitMirror.mirror(person)
        end
      end
    end

    # people.xml
    def self.load_people
      agent = Mechanize.new
      people_xml = agent.get "#{Rails.configuration.xml_data_base_url}members/people.xml"
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

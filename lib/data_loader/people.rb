require 'mechanize'

module DataLoader
  class People

    def self.member_to_person
      @member_to_person ||= load_people
    end

    private

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

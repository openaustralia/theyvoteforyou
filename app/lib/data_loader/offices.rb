# frozen_string_literal: true

require "mechanize"

module DataLoader
  class Offices
    # ministers.xml
    def self.load!
      Rails.logger.info "Reloading offices..."
      agent = Mechanize.new
      ministers_xml = agent.get "#{Rails.configuration.xml_data_base_url}members/ministers.xml"
      Rails.logger.info "Deleted #{Office.delete_all} offices"
      ministers_xml.search(:moffice).each do |moffice|
        person_id_long = People.member_to_person[moffice[:matchid]]
        raise "MP #{moffice[:name]} has no person" unless person_id_long

        person_id = person_id_long[%r{uk.org.publicwhip/person/(\d*)}, 1]
        person = Person.find_by(id: person_id)
        raise "Office #{moffice[:id]} points to a non existent person" if person.nil?

        responsibility = moffice[:responsibility] || ""

        Office.create!(id: moffice[:id][%r{uk.org.publicwhip/moffice/(\d*)}, 1],
                       person: person,
                       dept: moffice[:dept],
                       position: moffice[:position],
                       responsibility: responsibility,
                       from_date: moffice[:fromdate],
                       to_date: moffice[:todate])
      end
      Rails.logger.info "Loaded #{Office.count} offices"
    end
  end
end

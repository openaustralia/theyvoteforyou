require "open-uri"
require "json"

module DataLoader
  class Popolo
    def self.load!(url)
      Rails.logger.info "Loading Popolo data from #{url}..."
      data = JSON.parse(open(url).read)

      organizations = data["organizations"]
      areas = data["areas"]

      people = data["persons"]
      Rails.logger.info "Loading #{people.count} people..."
      people.each do |p|
        person = Person.find_or_initialize_by(id: p["id"][/\d+/])
        person.small_image_url = p["image"]
        person.large_image_url = p["image"]
        person.save!
      end

      members = data["memberships"]
      Rails.logger.info "Loading #{members.count} memberships..."
      members.each do |m|
        raise "Person not found: #{m["person_id"]}" unless person = people.find { |p| p["id"] == m["person_id"] }
        raise "Party not found: #{m["on_behalf_of_id"]}" unless party = organizations.find { |o| o["id"] == m["on_behalf_of_id"] }
        raise "Area not found: #{m["area_id"]}" unless area = areas.find { |a| a["id"] == m["area_id"] }
        # TODO: Instead of reusing the person ID we need a unique ID for this member
        member = Member.find_or_initialize_by(gid: m["person_id"][/\d+/])
        member.source_gid = m["person_id"]
        member.first_name = person["given_name"]
        member.last_name = person["family_name"]
        member.title = ""
        member.constituency = area["name"]
        member.party = party["name"]
        # TODO: Remove hardcoded house
        member.house = "rada"
        # TODO: member.entered_house
        # TODO: member.left_house
        member.person_id = m["person_id"][/\d+/]
        member.save!
      end
    end
  end
end

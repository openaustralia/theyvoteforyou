require "open-uri"
require "json"

module DataLoader
  module Ukraine
    class Popolo
      def self.load!(url)
        Rails.logger.info "Loading Ukraine Popolo data from #{url}..."
        data = JSON.parse(open(url).read)

        if people = data["persons"]
          organizations = data["organizations"]
          areas = data["areas"]
          events = data["events"]

          Rails.logger.info "Loading #{people.count} people..."
          people.each do |p|
            person = Person.find_or_initialize_by(id: extract_rada_id_from_person(p))
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
            raise "Legislative period not found: #{m["legislative_period_id"]}" unless legislative_period = events.find { |e| e["id"] == m["legislative_period_id"] }
            person["rada_id"] = extract_rada_id_from_person(person)

            # Default to the start of the legislative period if there no specific one set for this membership
            start_date = m["start_date"] || legislative_period["start_date"]

            member = Member.find_or_initialize_by(person_id: person["rada_id"], entered_house: start_date)
            member.gid = m["person_id"]
            member.source_gid = person["rada_id"]
            member.first_name = person["given_name"]
            member.last_name = person["family_name"]
            member.title = ""
            member.constituency = area["name"]
            member.party = party["name"]
            # TODO: Remove hardcoded house
            member.house = "rada"
            member.entered_house = start_date
            member.left_house = m["end_date"] if m["end_date"]
            member.person_id = person["rada_id"]
            member.save!
          end
        elsif vote_events = data["vote_events"]
          Rails.logger.info "Loading #{vote_events.count} vote_events..."
          vote_events.each do |v_e|
            ActiveRecord::Base.transaction do
              division = Division.find_or_initialize_by(id: v_e["identifier"])
              division.date = DateTime.parse(v_e["start_date"]).strftime("%F")
              division.number = v_e["identifier"]
              division.house = v_e["organization_id"]
              division.name = v_e["title"]
              division.source_url = v_e["sources"].find { |s| s["note"] == "Source URL" }["url"]
              division.debate_url = v_e["sources"].find { |s| s["note"] == "Debate URL" }["url"]
              division.motion = ""
              division.clock_time = DateTime.parse(v_e["start_date"]).strftime("%T")
              division.source_gid = v_e["identifier"]
              division.debate_gid = ""
              division.result = v_e["result"]
              division.save!

              votes = v_e["votes"]
              Rails.logger.info "Loading #{votes.count} votes..."
              votes.each do |v|
                member = Member.current_on(division.date).find_by!(person_id: v["voter_id"])
                vote = division.votes.find_or_initialize_by(member: member)
                if option = popolo_to_publicwhip_vote(v["option"])
                  vote.vote = option
                  vote.save!
                else
                  vote.destroy
                end
              end

              bills = v_e["bills"]
              Rails.logger.info "Loading #{bills.count} bills..."
              bills.each do |b|
                # We need to use create here because otherwise the association isn't saved
                bill = division.bills.find_or_create_by(official_id: b["official_id"])
                bill.url = b["url"]
                bill.title = b["title"]
                bill.save!
              end
            end
          end
        else
          raise "No loadable data found"
        end
      end

      # TODO: This shouldn't be a class method - move it somewhere more sensible
      def self.extract_rada_id_from_person(person)
        person["identifiers"].find { |i| i["scheme"] == "rada" }["identifier"]
      end
    end
  end
end

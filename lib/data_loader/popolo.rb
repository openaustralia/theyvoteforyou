require "open-uri"
require "json"

module DataLoader
  class Popolo
    def self.load!(url)
      Rails.logger.info "Loading Popolo data from #{url}..."
      data = JSON.parse(open(url).read)

      if people = data["persons"]
        organizations = data["organizations"]
        areas = data["areas"]

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
          member = Member.find_or_initialize_by(id: m["person_id"][/\d+/])
          member.gid = m["person_id"][/\d+/]
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
      elsif vote_events = data["vote_events"]
        Rails.logger.info "Loading #{vote_events.count} vote_events..."
        vote_events.each do |v_e|
          ActiveRecord::Base.transaction do
            division = Division.find_or_initialize_by(id: v_e["identifier"])
            division.date = DateTime.parse(v_e["start_date"]).strftime("%F")
            division.number = v_e["identifier"]
            division.house = "rada" # TODO: Remove hardcoded value
            division.name = v_e["title"]
            division.source_url = "TODO"
            division.debate_url = "TODO"
            division.motion = "TODO"
            division.clock_time = DateTime.parse(v_e["start_date"]).strftime("%T")
            division.source_gid = v_e["identifier"]
            division.debate_gid = "TODO"
            division.save!

            votes = v_e["votes"]
            Rails.logger.info "Loading #{votes.count} votes..."
            votes.each do |v|
              vote = division.votes.find_or_initialize_by(member_id: v["voter_id"])
              if option = popolo_to_publicwhip_vote(v["option"])
                vote.vote = option
                vote.save!
              else
                vote.destroy
              end
            end
          end
        end
      else
        raise "No loadable data found"
      end
    end

    # TODO: This shouldn't be a class method - move it somewhere more sensible
    def self.popolo_to_publicwhip_vote(string)
      case string
      when "yes"
        "aye"
      when "no"
        "no"
      when "abstain"
        "abstention"
      when "absent"
        nil
      when "not voting"
        nil
      else
        raise "Unknown vote option: #{string}"
      end
    end
  end
end

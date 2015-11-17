require "open-uri"
require "json"

module DataLoader
  module Ukraine
    class VoteEvents
      BASE_URL = ENV["DEBUG_URL"] || "https://arcane-mountain-8284.herokuapp.com/vote_events/"

      def self.load!(date)
        url = BASE_URL + date.to_s
        Rails.logger.info "Loading Ukraine vote events from #{url}..."
        data = JSON.parse(open(url).read)

        if vote_events = data["vote_events"]
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
          "not voting"
        else
          raise "Unknown vote option: #{string}"
        end
      end
    end
  end
end

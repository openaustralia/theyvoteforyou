# frozen_string_literal: true

require "mechanize"
require_relative "people"

module DataLoader
  class Members
    class << self
      # representatives.xml & senators.xml
      def load!
        Rails.logger.info "Reloading representatives and senators..."
        agent = Mechanize.new
        %w[representatives senators].each do |file|
          Rails.logger.info "Loading #{file}..."
          xml = agent.get "#{Settings.xml_data_base_url}members/#{file}.xml"
          xml.search(:member).each do |member|
            # Ignores entries older than the 1997 UK General Election
            next if member[:todate] <= "1997-04-08"

            gid = member[:id]
            if gid.include?("uk.org.publicwhip/member/")
              raise "House mismatch" unless member[:house] == "representatives"

              id = gid[%r{uk.org.publicwhip/member/(\d*)}, 1]
            elsif gid.include?("uk.org.publicwhip/lord/")
              raise "House mismatch" unless member[:house] == "senate"

              id = gid[%r{uk.org.publicwhip/lord/(\d*)}, 1]
            else
              raise "Unknown gid type #{gid}"
            end

            person_id = People.member_to_person[member[:id]]
            raise "MP #{member[:id]} has no person" unless person_id

            person_id = person_id[%r{uk.org.publicwhip/person/(\d*)}, 1]
            Person.find_or_create_by!(id: person_id)
            m = Member.find_or_initialize_by(gid: gid, id: id)
            m.update!(first_name: member[:firstname],
                      last_name: member[:lastname],
                      title: member[:title],
                      constituency: member[:division],
                      party: member[:party],
                      house: member[:house],
                      entered_house: member[:fromdate],
                      left_house: member[:todate],
                      entered_reason: member[:fromwhy],
                      left_reason: member[:towhy],
                      person_id: person_id,
                      source_gid: "")
          end
        end
        Rails.logger.info "Loaded #{Member.count} members"
      end
    end
  end
end

require 'nokogiri'
require 'cgi'

module DataLoader
  class Members
    class << self
      # representatives.xml & senators.xml
      def load!
        Rails.logger.info "Reloading representatives and senators..."
        %w(representatives senators).each do |file|
          Rails.logger.info "Loading #{file}..."
          xml = Nokogiri.parse(File.read("#{Settings.xml_data_directory}/members/#{file}.xml"))
          xml.search(:member).each do |member|
            # Ignores entries older than the 1997 UK General Election
            next if member[:todate] <= '1997-04-08'

            house = member[:house]
            house = case house
                    when 'representatives'
                      'commons'
                    when 'senate'
                      'lords'
                    end

            gid = member[:id]
            if gid.include?('uk.org.publicwhip/member/')
              raise 'House mismatch' unless house == 'commons'
              id = gid[/uk.org.publicwhip\/member\/(\d*)/, 1]
            elsif gid.include?('uk.org.publicwhip/lord/')
              raise 'House mismatch' unless house == 'lords'
              id = gid[/uk.org.publicwhip\/lord\/(\d*)/, 1]
            else
              raise "Unknown gid type #{gid}"
            end

            person_id = People.member_to_person[member[:id]]
            raise "MP #{member[:id]} has no person" unless person_id
            person_id = person_id[/uk.org.publicwhip\/person\/(\d*)/, 1]

            m = Member.find_or_initialize_by(gid: gid, id: id)
            m.update!(first_name: XML.escape_html(member[:firstname]),
                           last_name: XML.escape_html(member[:lastname]),
                           title: member[:title],
                           constituency: XML.escape_html(member[:division]),
                           party: member[:party],
                           house: house,
                           entered_house: member[:fromdate],
                           left_house: member[:todate],
                           entered_reason: member[:fromwhy],
                           left_reason: member[:towhy],
                           person_id: person_id,
                           source_gid: '')
          end
        end
        Rails.logger.info "Loaded #{Member.count} members"
      end
    end
  end
end

require "mechanize"

module DataLoader
  class Debates
    # from_date - Date to parse from (just specify this date if you only want one )
    # to_date - A single date
    def self.load!(from_date, to_date = nil)
      agent = Mechanize.new

      (from_date..(to_date || from_date)).each do |date|
        House.australian.each do |house|
          url = "#{Settings.xml_data_base_url}scrapedxml/#{house}_debates/#{date}.xml"
          begin
            xml_document = Nokogiri::XML(agent.get(url).body)
          rescue Mechanize::ResponseCodeError => e
            if e.response_code == "404"
              Rails.logger.info "No XML file found for #{house} on #{date} at #{url}"
              next
            else
              raise e
            end
          end

          existing_divisions = Division.where(date: date, house: house)

          debates = DebatesXML.new(xml_document, house)
          Rails.logger.info "No debates found in XML for #{house} on #{date}" if debates.divisions.empty?

          if existing_divisions && existing_divisions.count != debates.divisions.count
            Rails.logger.warn "Division reload mismatch! #{house} #{date}: #{existing_divisions.count} divisions in the database and #{debates.divisions.count} in the XML"
          end

          debates.divisions.each do |d|
            Rails.logger.info "Saving division: #{d.house} #{d.date} #{d.number}"
            ActiveRecord::Base.transaction do
              bills = d.bills.map do |bill_hash|
                bill = Bill.find_or_initialize_by(official_id: bill_hash[:id])
                bill.update!(url: bill_hash[:url], title: bill_hash[:title])
                bill
              end

              division = Division.find_or_initialize_by(date: d.date, number: d.number, house: d.house)
              division.update!(valid: true,
                               name: d.name,
                               source_url: d.source_url,
                               debate_url: d.debate_url,
                               source_gid: d.source_gid,
                               debate_gid: d.debate_gid,
                               motion: d.motion,
                               clock_time: d.clock_time,
                               bills: bills)

              division.votes.delete_all(:delete_all)
              d.votes.each do |gid, vote|
                member = Member.find_by!(gid: gid)
                Vote.create!(division: division, member: member, vote: vote[0], teller: vote[1])
              end
            end
          end
        end
      end
    end
  end
end

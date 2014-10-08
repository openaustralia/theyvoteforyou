require 'mechanize'

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
            xml_document = agent.get url
          rescue Mechanize::ResponseCodeError => e
            if e.response_code == '404'
              Rails.logger.info "No XML file found for #{house} on #{date} at #{url}"
              next
            else
              raise e
            end
          end

          debates = DebatesXML.new(xml_document, house)
          Rails.logger.info "No debates found in XML for #{house} on #{date}" if debates.divisions.empty?
          debates.divisions.each do |d|
            Rails.logger.info "Saving division: #{d.house} #{d.date} #{d.number}"
            ActiveRecord::Base.transaction do
              division = Division.find_or_initialize_by(date: d.date, number: d.number, house: d.house)
              division.update!(valid: true,
                               name: d.name,
                               source_url: d.source_url,
                               debate_url: d.debate_url,
                               source_gid: d.source_gid,
                               debate_gid: d.debate_gid,
                               motion: d.motion,
                               clock_time: d.clock_time,
                               notes: '',
                               bill_id: d.bill_id,
                               bill_url: d.bill_url)
              d.votes.each do |gid, vote|
                member = Member.find_by!(gid: gid)
                v = Vote.find_or_initialize_by(division: division, member: member)
                v.update!(vote: vote[0], teller: vote[1])
              end
            end
          end
        end
      end
    end
  end
end

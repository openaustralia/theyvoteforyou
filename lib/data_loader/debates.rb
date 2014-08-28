module DataLoader
  class Debates
    # The options hash takes:
    # :from_date - Date to parse from (just specify this date if you only want one )
    # :to_date - A single date
    def self.load!(options = {})
      dates = if options[:to_date]
                Date.parse(options[:from_date])..Date.parse(options[:to_date])
              else
                [Date.parse(options[:from_date])]
              end

      House.australian.each do |house|
        dates.each do |date|
          # TODO: Check for the file first rather than catching the exception
          filename = "#{Settings.xml_data_directory}/scrapedxml/#{house}_debates/#{date}.xml"
          begin
            xml_data = File.read(filename)
          rescue Errno::ENOENT
            Rails.logger.info "No XML file found for #{house} on #{date} at #{filename}"
            next
          end

          debates = DebatesXML.new(xml_data, house)
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
                               notes: '')
              # TODO: Check for existing votes in the database
              d.votes.each do |gid, vote|
                Vote.find_or_create_by!(division: division, member: Member.find_by!(gid: gid), vote: vote)
              end
            end
          end
        end
      end
    end
  end
end

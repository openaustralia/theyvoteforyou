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

      dates.each do |date|
        House.australian.each do |house|
          # TODO: Check for the file first rather than catching the exception
          begin
            xml_data = File.read("#{Settings.xml_data_directory}/scrapedxml/#{house}_debates/#{date}.xml")
          rescue Errno::ENOENT
            Rails.logger.info "No XML file found for #{house} on #{date}"
            next
          end

          debates = DebatesXML.new(xml_data, house)
          Rails.logger.info "No debates found in XML for #{house} on #{date}" if debates.divisions.empty?
          debates.divisions.each do |division|
            Rails.logger.info "Saving division: #{division.house} #{division.date} #{division.number}"
            division.save!
          end
        end
      end
    end
  end
end

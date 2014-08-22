module DataLoader
  # TODO: Rename this class - it's a lover^Wloader not a fighter^Wparser
  class DebatesParser
    # +xml_directory+ scrapedxml directory, e.g. files from http://data.openaustralia.org/scrapedxml/
    # The options hash takes:
    # +:house+ specify representatives or senate, omit for both
    # +:date+ A single date
    def self.run!(xml_directory, options = {})
      houses = case
               when options[:house].nil?
                 House.australian
               when House.australian.include?(options[:house])
                 [options[:house]]
               else
                 raise "Invalid house: #{options[:house]}"
               end

      houses.each do |house|
        # TODO: Check for the file first rather than catching the exception
        begin
          xml_data = File.read("#{Settings.xml_data_directory}/scrapedxml/#{house}_debates/#{options[:date]}.xml")
        rescue Errno::ENOENT
          Rails.logger.info "No XML file found for #{house} on #{options[:date]}"
          next
        end

        debates = DebatesXML.new(xml_data, house)
        Rails.logger.info "No debates found in XML for #{house} on #{options[:date]}" if debates.divisions.empty?
        debates.divisions.each do |division|
          Rails.logger.info "Saving division: #{division.house} #{division.date} #{division.number}"
          division.save!
        end
      end
    end
  end
end

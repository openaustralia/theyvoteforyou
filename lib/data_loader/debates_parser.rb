require 'nokogiri'

module DataLoader
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
        begin
          xml_document = Nokogiri.parse(File.read("#{xml_directory}/#{house}_debates/#{options[:date]}.xml"))
        rescue Errno::ENOENT
          Rails.logger.info "No XML file found for #{house} on #{options[:date]}"
          next
        end

        debates = DebatesXML.new(xml_document, house)
        debates.divisions.each do |division|
          Rails.logger.info "Saving division: #{division.house} #{division.date} #{division.number}"
          division.save!
        end
      end
    end
  end
end

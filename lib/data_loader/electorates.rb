require 'nokogiri'

module DataLoader
  class Electorates
    # divisions.xml
    def self.load!
      Rails.logger.info "Reloading electorates..."
      Rails.logger.info "Deleted #{Electorate.delete_all} electorates"
      electorates_xml = Nokogiri.parse(File.read("#{Settings.xml_data_directory}/members/divisions.xml"))
      electorates_xml.search(:division).each do |division|
        Electorate.create!(cons_id: division[:id][/uk.org.publicwhip\/cons\/(\d*)/, 1],
                           # TODO: Support multiple electorate names
                           name: XML.escape_html(division.at(:name)[:text]),
                           main_name: true,
                           from_date: division[:fromdate],
                           to_date: division[:todate],
                           # TODO: Support Scottish parliament
                           house: 'commons')
      end
      Rails.logger.info "Loaded #{Electorate.count} electorates"
    end
  end
end

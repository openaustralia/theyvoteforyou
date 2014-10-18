require 'mechanize'

module DataLoader
  class Electorates
    # divisions.xml
    def self.load!
      Rails.logger.info "Reloading electorates..."
      agent = Mechanize.new
      electorates_xml = agent.get "#{Settings.xml_data_base_url}members/divisions.xml"
      electorates_xml.search(:division).each do |division|
        e = Electorate.find_or_initialize_by(id: division[:id][/uk.org.publicwhip\/cons\/(\d*)/, 1])
        # TODO: Support multiple electorate names
        e.update!(name: XML.escape_html(division.at(:name)[:text]),
          main_name: true,
          from_date: division[:fromdate],
          to_date: division[:todate],
          # TODO: Support Scottish parliament
          house: 'representatives')
      end
      Rails.logger.info "Loaded #{Electorate.count} electorates"
    end
  end
end

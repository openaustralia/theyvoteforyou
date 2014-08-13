require 'nokogiri'

class DataLoader
  class << self
    def reload_electorates(xml_file)
      puts "Deleted #{Electorate.delete_all} electorates"

      electorates_xml = Nokogiri.parse(File.read(xml_file))
      electorates_xml.search(:division).each do |division|
        Electorate.create!(cons_id: division[:id][/uk.org.publicwhip\/cons\/(\d*)/, 1],
                           # TODO: Support multiple electorate names
                           name: division.at(:name)[:text],
                           main_name: true,
                           from_date: division[:fromdate],
                           to_date: division[:todate],
                           # TODO: Support Scottish parliament
                           house: 'commons')
      end

      puts "Loaded #{Electorate.count} electorates"
    end
  end
end

require 'nokogiri'

module DataLoader
  class DebatesXML
    def initialize(xml_data, house)
      @xml_document = Nokogiri.parse(xml_data)
      raise 'Debate data missing' unless @xml_document.at(:debates)
      @house = house
    end

    def divisions
      @xml_document.search(:division).map { |division| DivisionXML.new(division, @house) }
    end
  end
end

module DataLoader
  class DebatesXML
    def initialize(xml_document, house)
      raise 'Debate data missing' unless xml_document.at(:debates)
      @debates_xml, @house = xml_document, house
    end

    def divisions
      @debates_xml.search(:division).map do |division|
        DivisionXML.new(division, @house)
      end
    end
  end
end

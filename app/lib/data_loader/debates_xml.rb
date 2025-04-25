# frozen_string_literal: true

module DataLoader
  class DebatesXml
    def initialize(xml_document, house)
      @xml_document = xml_document
      raise "Debate data missing" unless @xml_document.at(:debates)

      @house = house
    end

    def divisions
      @xml_document.search(:division).map { |division| DivisionXml.new(division, @house) }
    end
  end
end

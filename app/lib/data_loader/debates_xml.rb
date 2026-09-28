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

    # Every <speech> in a section headed by a minor heading with this title, in document
    # order. Used by the AI division summary pipeline to find the earlier sitting days of a
    # debate (a bill's second reading often runs over several days, and a deferred division
    # is put on a later day than the debate it decides). Sections run until the next heading.
    def speeches_under_minor_heading(title)
      wanted = self.class.normalise_heading(title)
      return [] if wanted.empty?

      @xml_document.search("minor-heading").select { |heading| self.class.normalise_heading(heading.text) == wanted }
                   .flat_map { |heading| section_speeches(heading) }
    end

    # Headings are compared ignoring case and spacing, which vary between days for the
    # same debate.
    def self.normalise_heading(text)
      text.to_s.gsub(/[[:space:]]+/, " ").strip.downcase
    end

    private

    def section_speeches(heading)
      speeches = []
      element = heading.next_element
      while element&.name&.exclude?("heading")
        speeches << element if element.name == "speech"
        element = element.next_element
      end
      speeches
    end
  end
end

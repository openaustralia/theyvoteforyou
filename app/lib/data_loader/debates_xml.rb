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

    # Every <speech> in a section headed by a minor heading with this title, or about one of
    # these bills, in document order. Used by the AI division summary pipeline to find the
    # earlier sitting days of a debate (a bill's second reading often runs over several days,
    # and a deferred division is put on a later day than the debate it decides). Sections run
    # until the next heading.
    #
    # A bill's stages sit under different headings ("...; Second Reading", "...; In Committee",
    # "...; Limitation of Debate"), so the title alone misses a question put under one stage's
    # heading about something moved under another's. The bills listed under each heading are
    # what tie them together.
    def speeches_under_minor_heading(title, bill_ids: [])
      wanted = self.class.normalise_heading(title)
      return [] if wanted.empty? && bill_ids.empty?

      headings = @xml_document.search("minor-heading").select do |heading|
        self.class.same_debate_section?(heading, wanted, bill_ids)
      end
      headings.flat_map { |heading| section_speeches(heading) }
    end

    # Whether the section under this heading is the debate with this title (as #normalise_heading
    # gives it), or is about one of these bills.
    def self.same_debate_section?(heading, title, bill_ids)
      return false unless heading

      normalise_heading(heading.text) == title || section_bill_ids(heading).intersect?(bill_ids)
    end

    # Headings are compared ignoring case and spacing, which vary between days for the
    # same debate.
    def self.normalise_heading(text)
      text.to_s.gsub(/[[:space:]]+/, " ").strip.downcase
    end

    # The heading of the section a speech or division sits in: its nearest preceding minor
    # heading, or the major heading when there is none.
    def self.section_heading(node)
      node.at_xpath("preceding::minor-heading[1]") || node.at_xpath("preceding::major-heading[1]")
    end

    # The ParlParse ids ("r7339") of the bills a section is about. Current ParlParse XML lists
    # them in a <bills> element straight after the section's minor heading; older files have
    # none, and neither does a section that is not about a bill.
    def self.section_bill_ids(heading)
      bills = heading&.next_element
      return [] unless bills&.name == "bills"

      bills.search("bill").filter_map { |bill| bill.attr(:id).presence }
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

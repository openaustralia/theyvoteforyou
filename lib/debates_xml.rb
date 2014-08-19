require 'nokogiri'

module DebatesXML
  class Parser
    def initialize(file_path, house)
      @house = house
      raise "Invalid house #{house}" unless house == 'commons' || house == 'lords'

      @debates_xml = Nokogiri.parse(File.read(file_path))
      raise 'Debate data missing' unless @debates_xml.at(:debates)
    end

    def divisions
      @debates_xml.search(:division).map do |division|
        Division.new(division, @house)
      end
    end
  end

  class Division
    def initialize(division_xml, house)
      @division_xml, @house = division_xml, house
    end

    def date
      @division_xml.attr(:divdate)
    end

    def number
      @division_xml.attr(:divnumber)
    end

    def house
      @house
    end

    def name
      # TODO: Called $heading in perl
    end

    def source_url
      # TODO
    end

    def debate_url
      # TODO
    end

    def source_gid
      # TODO
    end

    def debate_gid
      # TODO
    end

    def motion
      # TODO
    end

    def clock_time
      time = @division_xml.attr(:time)
      time = "#{time}:00" if time =~ /^\d\d:\d\d$/
      time = "0#{time}" if time =~ /^\d\d:\d\d:\d\d$/

      if time !~ /^\d\d\d:\d\d:\d\d$/
        Rails.logger.warn "Clock time '#{time}' not in right format"
        ''
      else
        time
      end
    end

    private

    def major_heading
      find_previous_element(@division_xml, 'major-heading').inner_text.strip
    end

    def minor_heading
      find_previous_element(@division_xml, 'minor-heading').inner_text.strip
    end

    def find_previous_element(element, name)
      previous_element = element.previous_element
      while previous_element.name != name
        previous_element = previous_element.previous_element
      end
      previous_element
    end
  end
end

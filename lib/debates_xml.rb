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
      title_case(preceeding_major_heading_element.inner_text.strip + ' &#8212; ' + preceeding_minor_heading_element.inner_text.strip)
    end

    def source_url
      @division_xml.attr(:url)
    end

    def debate_url
      preceeding_minor_heading_element.attr(:url)
    end

    def source_gid
      @division_xml.attr(:id)
    end

    def debate_gid
      preceeding_minor_heading_element.attr(:id)
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

    def preceeding_major_heading_element
      find_previous_element(@division_xml, 'major-heading')
    end

    def preceeding_minor_heading_element
      find_previous_element(@division_xml, 'minor-heading')
    end

    def find_previous_element(element, name)
      previous_element = element.previous_element
      while previous_element.name != name
        previous_element = previous_element.previous_element
      end
      previous_element
    end

    def title_case(title)
      title = title.titlecase
      # Un-titlecase words in the skip list from Perl's Text::Autoformat
      skip_words = %w(a an at as and are
                      but by
                      ere
                      for from
                      in into is
                      of on onto or over
                      per
                      the to that than
                      until unto upon
                      via
                      with while whilst within without)
      title.split.map { |w| skip_words.include?(w.downcase) ? w.downcase : w }.join(' ')
    end
  end
end

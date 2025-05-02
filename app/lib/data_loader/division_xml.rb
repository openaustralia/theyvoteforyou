# frozen_string_literal: true

module DataLoader
  class DivisionXml
    MAXIMUM_MOTION_TEXT_SIZE = 15000

    attr_accessor :division_xml, :house

    def initialize(division_xml, house)
      self.division_xml = division_xml
      self.house = house
    end

    def date
      division_xml.attr(:divdate)
    end

    def number
      division_xml.attr(:divnumber)
    end

    def name
      text = if major_heading.present? && minor_heading.present?
               "#{title_case(major_heading)} &#8212; #{title_case(minor_heading)}"
             elsif major_heading.present?
               title_case(major_heading)
             elsif minor_heading.present?
               title_case(minor_heading)
             end

      text.gsub("—", " &#8212; ")
    end

    def source_url
      division_xml.attr(:url)
    end

    def debate_url
      # TODO: PHP always gets the previous heading, major or minor. Is this to support missing headings?
      preceeding_minor_heading_element.attr(:url)
    end

    def debate_gid
      # TODO: PHP always gets the previous heading, major or minor. Is this to support missing headings?
      preceeding_minor_heading_element.attr(:id)
    end

    def motion
      truncated_pwmotiontexts = truncate_for_motion(pwmotiontexts.map { |p| "#{p}\n\n" })

      text = truncated_pwmotiontexts.empty? ? truncate_for_motion(previous_speeches.map { |s| speech_text s }) : truncated_pwmotiontexts
      text.blank? ? '<p class="motion-notice motion-notice-notext">No motion text available</p>' : encode_html_entities(text)
    end

    def clock_time
      time = division_xml.attr(:time)
      time = "#{time}:00" if time =~ /^\d\d:\d\d$/
      time = "0#{time}" if time =~ /^\d\d:\d\d:\d\d$/

      if time =~ /^\d\d\d:\d\d:\d\d$/
        time
      else
        Rails.logger.warn "Clock time '#{time}' not in right format"
        ""
      end
    end

    # Returns a hash of votes in the form of member gid => [vote, teller]
    # TODO Make it an array of hashes like {gid: ..., vote: ..., teller: ...}
    def votes
      votes = division_xml.xpath("memberlist/member").map do |vote_xml|
        gid = vote_xml.attr(:id)
        teller = vote_xml.attr(:teller) == "yes"
        vote = vote_xml.attr(:vote)
        [gid, [vote, teller]]
      end
      votes.to_h
    end

    def bills
      division_xml.search("bills bill").map do |bill|
        { id: bill.attr(:id), url: bill.attr(:url), title: bill.inner_text }
      end
    end

    private

    def preceeding_major_heading_element
      find_previous("major-heading")
    end

    def major_heading
      preceeding_major_heading_element.inner_text.strip
    end

    def preceeding_minor_heading_element
      find_previous("minor-heading")
    end

    def minor_heading
      preceeding_minor_heading_element.inner_text.strip
    end

    def find_previous(name)
      previous_element = division_xml.previous_element
      previous_element = previous_element.previous_element while previous_element.name != name
      previous_element
    end

    def pwmotiontexts
      previous_element = division_xml.previous_element
      pwmotiontexts = []
      while previous_element&.name&.exclude?("heading") && previous_element&.name.exclude?("division")
        pwmotiontexts << previous_element.xpath("p[@pwmotiontext]") unless previous_element.xpath("p[@pwmotiontext]").empty?
        previous_element = previous_element.previous_element
      end
      pwmotiontexts.reverse
    end

    def previous_speeches
      previous_element = division_xml.previous_element
      speeches = []
      while previous_element&.name&.exclude?("heading") && previous_element&.name.exclude?("division")
        speeches << previous_element if previous_element.name == "speech"
        previous_element = previous_element.previous_element
      end
      speeches.reverse
    end

    def speech_text(speech)
      speaker = speech_speaker(speech)
      speech = speech.children.to_html # to_html oddly gets us closest to PHP's output
      speech.gsub!("\n", "") # Except that Nokogiri is adding newlines :(
      speech.gsub!("</p>", "</p>\n\n") # PHP loader does this "so that the website formatter doesn't do strange things"

      if speaker
        speaker.gsub!("'", "&#39;")
        "<p class=\"speaker\">#{speaker}</p>\n\n#{speech}"
      else
        "\n\n#{speech}"
      end
    end

    def truncate_for_motion(elements)
      truncation_text = "<p class='motion-notice motion-notice-truncated'>Long debate text truncated.</p>"
      output_text = ""

      elements.each do |element|
        if (output_text + element).size > (MAXIMUM_MOTION_TEXT_SIZE - truncation_text.size)
          Rails.logger.warn "Truncating very long motion text for division: #{house} #{date} #{number}"
          output_text += truncation_text
          break
        else
          output_text += element
        end
      end

      output_text
    end

    # Encode certain HTML entities as found in PHP loader
    def encode_html_entities(text)
      text.gsub!("—", "&#8212;") # em dash
      text.gsub!("‘", "&#8216;")
      text.gsub!("’", "&#8217;")
      text.gsub!("“", "&#8220;")
      text.gsub!("”", "&#8221;")
      text.gsub!("½", "&#189;")
      text.gsub!("…", "&#8230;")
      text.gsub!("£", "&#163;")
      text.gsub(" ", "&#160;") # nbsp
    end

    def speech_speaker(speech)
      member = Member.find_by(gid: speech.attr(:speakerid))
      member ? member.name : speech.attr(:speakername)
    end

    def title_case(title)
      title = title.downcase.gsub(/\b(?<!['’`])[a-z]/) { Regexp.last_match(0).capitalize }
      # Un-titlecase words in the skip list from Perl's Text::Autoformat
      skip_words = %w[a an at as and are
                      but by
                      ere
                      for from
                      in into is
                      of on onto or over
                      per
                      the to that than
                      until unto upon
                      via
                      with while whilst within without]
      title.split.map.with_index do |w, i|
        # Never lower case the first word
        i != 0 && skip_words.include?(w.downcase) ? w.downcase : w
      end.join(" ")
    end
  end
end

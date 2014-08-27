module DataLoader
  class DivisionXML
    MAXIMUM_MOTION_TEXT_SIZE = 15000

    def initialize(division_xml, house)
      @division_xml = division_xml
      @house = House.australian_to_uk(house)
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
      text = if !major_heading.blank? && !minor_heading.blank?
        major_heading + ' &#8212; ' + minor_heading
      elsif !major_heading.blank?
        major_heading
      elsif !minor_heading.blank?
        minor_heading
      end
      title_case(text).gsub('—', ' &#8212; ')
    end

    def source_url
      @division_xml.attr(:url)
    end

    def debate_url
      # TODO: PHP always gets the previous heading, major or minor. Is this to support missing headings?
      preceeding_minor_heading_element.attr(:url)
    end

    def source_gid
      @division_xml.attr(:id)
    end

    def debate_gid
      # TODO: PHP always gets the previous heading, major or minor. Is this to support missing headings?
      preceeding_minor_heading_element.attr(:id)
    end

    def motion
      pwmotiontext = pwmotiontexts.map { |p| p.to_s + "\n\n" }.join
      text = pwmotiontext.empty? ? previous_speeches_motion_text : pwmotiontext
      # Truncate really long motion text at the same size as formatted_motion_text
      Rails.logger.warn "Truncating very long motion text for division: #{house} #{date} #{number}" if text.size > 15000
      encode_html_entities(text.truncate MAXIMUM_MOTION_TEXT_SIZE)
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

    def save!
      ActiveRecord::Base.transaction do
        division = Division.find_or_initialize_by(date: date, number: number, house: house)
        division.update!(valid: true,
                         name: name,
                         source_url: source_url,
                         debate_url: debate_url,
                         source_gid: source_gid,
                         debate_gid: debate_gid,
                         motion: motion,
                         clock_time: clock_time,
                         notes: '')
        save_votes(division)
      end
    end

    private

    def save_votes(division)
      # TODO: Check for existing votes in the database
      @division_xml.search(:member).each do |vote_xml|
        member = Member.find_by!(gid: vote_xml.attr(:id))
        vote = vote_xml.attr(:teller) == 'yes' ? "tell#{vote_xml.attr(:vote)}" : vote_xml.attr(:vote)
        Vote.find_or_create_by!(division: division, member: member, vote: vote)
      end
    end

    def preceeding_major_heading_element
      find_previous('major-heading')
    end

    def major_heading
      preceeding_major_heading_element.inner_text.strip
    end

    def preceeding_minor_heading_element
      find_previous('minor-heading')
    end

    def minor_heading
      preceeding_minor_heading_element.inner_text.strip
    end

    def find_previous(name)
      previous_element = @division_xml.previous_element
      while previous_element.name != name
        previous_element = previous_element.previous_element
      end
      previous_element
    end

    def pwmotiontexts
      previous_element = @division_xml.previous_element
      pwmotiontexts = []
      while previous_element && !previous_element.name.include?('heading') && !previous_element.name.include?('division')
        pwmotiontexts << previous_element.xpath('p[@pwmotiontext]') unless previous_element.xpath('p[@pwmotiontext]').empty?
        previous_element = previous_element.previous_element
      end
      pwmotiontexts.reverse
    end

    def previous_speeches
      previous_element = @division_xml.previous_element
      speeches = []
      while previous_element && !previous_element.name.include?('heading') && !previous_element.name.include?('division')
        speeches << previous_element if previous_element.name == 'speech'
        previous_element = previous_element.previous_element
      end
      speeches.reverse
    end

    def speech_text(speech)
      speaker = speech_speaker(speech)
      speech = speech.children.to_html # to_html oddly gets us closest to PHP's output
      speech.gsub!("\n", '') # Except that Nokogiri is adding newlines :(
      speech.gsub!('</p>', "</p>\n\n") # PHP loader does this "so that the website formatter doesn't do strange things"
      "<p class=\"speaker\">#{speaker}</p>\n\n#{speech}"
    end

    def previous_speeches_motion_text
      truncation_text = "<p>Long debate text truncated.</p>"
      output_text = ''

      previous_speeches.map { |s| speech_text s }.each do |speech|
        if (output_text + speech).size > (MAXIMUM_MOTION_TEXT_SIZE - truncation_text.size)
          output_text += truncation_text
          break
        else
          output_text += speech
        end
      end

      output_text
    end

    # Encode certain HTML entities as found in PHP loader
    def encode_html_entities(text)
      text.gsub!('—', '&#8212;') # em dash
      text.gsub!('‘', '&#8216;')
      text.gsub!('’', '&#8217;')
      text.gsub!('“', '&#8220;')
      text.gsub!('”', '&#8221;')
      text.gsub(' ', '&#160;') # nbsp
    end

    def speech_speaker(speech)
      member = Member.find_by(gid: speech.attr(:speakerid))
      member ? member.name_without_title : speech.attr(:speakername)
    end

    def title_case(title)
      title = title.downcase.gsub(/\b(?<!['’`])[a-z]/) { $&.capitalize }
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

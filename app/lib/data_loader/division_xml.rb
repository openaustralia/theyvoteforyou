# frozen_string_literal: true

module DataLoader
  class DivisionXml
    MAXIMUM_MOTION_TEXT_SIZE = 15000

    # How many speeches DivisionSummaryPipeline::ContextBuilder asks for at each context
    # tier when building an LLM prompt (see #context_speeches). Not used by the loader itself.
    CONTEXT_SPEECH_LIMITS = { immediate: 5, subdebate: 25, sitting_day: 200 }.freeze

    # The chair putting a question, or saying one was deferred, as against a member debating it
    # (see #preceded_by_division?). Current Hansard names the member in the chair like any other
    # speaker, so the words are all there is to go on; the length cap keeps a member's speech
    # that happens to say "the question is" from passing as one.
    CHAIR_STATEMENT = /\bquestion\s+(?:is|now\s+is|we're\s+dealing\s+with)\b|\bdeferred\b/i
    CHAIR_STATEMENT_MAXIMUM_SIZE = 1200

    # Also used by DivisionSummaryPipeline::EarlierDebate, so the two agree on what the chair says.
    def self.chair_statement_text?(text)
      text = text.to_s.strip
      text.size <= CHAIR_STATEMENT_MAXIMUM_SIZE && text.match?(CHAIR_STATEMENT)
    end

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
      preceding_minor_heading_element.attr(:url)
    end

    def debate_gid
      # TODO: PHP always gets the previous heading, major or minor. Is this to support missing headings?
      preceding_minor_heading_element.attr(:id)
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

    # The exact wording of the question being decided at this division: the operative
    # <p pwmotiontext> paragraph nearest the division - the same source #motion's primary
    # case reads from - falling back to the nearest preceding speech when no motion-text
    # paragraph precedes the division (see #motion for why that happens). Used by
    # DivisionSummaryPipeline::ContextBuilder to anchor procedural routing on the actual
    # question Hansard records, rather than a second, independent read of this XML.
    #
    # Current ParlParse XML carries no pwmotiontext attributes at all (motion text is
    # <p class="italic">), so for recent divisions this is the last speech before the
    # division: usually the chair's "The question is ...", which is often only a reference
    # such as "the motion moved by the member for Fadden". ContextBuilder therefore also reads
    # the motion as moved (DataLoader::SpeechText#moved_text) rather than relying on this alone.
    def operative_question
      nearest_motion_text = pwmotiontexts.last
      return nearest_motion_text.text.strip if nearest_motion_text.present?

      last_speech = previous_speeches.last
      SpeechText.paragraph_text(last_speech) if last_speech
    end

    # Speeches leading up to this division, for building wider prompt context than the
    # single motion paragraph #motion returns. :subdebate (the default) is the same speech
    # list #motion falls back to - previous siblings up to the last heading or another
    # division. :immediate is the tail of that list; :sitting_day widens the search to
    # every speech anywhere earlier in the day's XML, via Nokogiri's "preceding" axis
    # rather than a hand-rolled document walk. Each is a DataLoader::SpeechText#context_speech
    # hash.
    #
    # A long debate runs past the :subdebate limit, and the motion it decides was moved at the
    # start of it, so the tail alone can hold nothing but argument and a closure motion. The
    # latest speech that moved something before the tail is therefore kept in front of it.
    def context_speeches(level = :subdebate)
      speeches = level == :sitting_day ? division_xml.xpath("preceding::speech").to_a : previous_speeches
      limit = CONTEXT_SPEECH_LIMITS.fetch(level, CONTEXT_SPEECH_LIMITS[:subdebate])
      selected = speeches.last(limit)

      if level == :subdebate
        earlier_move = speeches[0...-limit].reverse.find { |speech| SpeechText.moved_text(speech) }
        selected = [earlier_move, *selected] if earlier_move
      end

      selected.map { |speech| SpeechText.context_speech(speech) }
    end

    # The title of the debate this division sits in: the nearest preceding minor heading
    # ("Example Bill 2026; Second Reading"), or the major heading when there is none. Raw
    # Hansard text, unlike #name, so it can be compared with the same heading elsewhere.
    def debate_title
      heading = division_xml.at_xpath("preceding::minor-heading[1]") || division_xml.at_xpath("preceding::major-heading[1]")
      heading&.text.to_s.gsub(/[[:space:]]+/, " ").strip
    end

    # Speeches from earlier in the same debate on this sitting day that the :subdebate tier
    # cannot reach: those before an earlier division under this heading, and those under an
    # earlier appearance of the same heading, as when a debate is interrupted by Question Time
    # and resumed under a repeated heading. DebatesXml#speeches_under_minor_heading does the same
    # for other sitting days.
    def earlier_same_debate_speeches
      title = DebatesXml.normalise_heading(debate_title)
      return [] if title.empty?

      already_read = previous_speeches.map(&:pointer_id)
      division_xml.xpath("preceding::speech").select do |speech|
        next false if already_read.include?(speech.pointer_id)

        section = speech.at_xpath("preceding::minor-heading[1]") || speech.at_xpath("preceding::major-heading[1]")
        section && DebatesXml.normalise_heading(section.text) == title
      end
    end

    # True when this division follows another with no debate between them. Where divisions
    # follow one another with no intervening debate the bells are rung for one minute and the
    # questions are put in a run (House S.O. 131, Guide p. 57; the Senate equivalent in Senate
    # Guide No. 3), which means only the first of the run has the debate about it in front of
    # it. DivisionSummaryPipeline::ContextBuilder uses this to warn that the debate about this
    # question may sit before the earlier division.
    #
    # The chair's own words between two divisions ("The question now is that the amendment
    # moved by ... be agreed to") are how a run is put, so they do not break it. Any other
    # speech (a member moving the next amendment, say) means the debate about this question is
    # right there. Checking for any earlier division under the same heading, as this once did,
    # raised the warning for every amendment after the first in a Senate second reading debate.
    def preceded_by_division?
      run_elements.any? { |element| element.name == "division" }
    end

    # What the chair said while putting the run of divisions this one ends, earliest first,
    # including the statement just before this division. Only the first question of a deferred
    # run says it was deferred ("In accordance with standing order 133, I shall now proceed to
    # put the question on ..."), so the later ones inherit that from here.
    def run_statements
      run_elements.select { |element| element.name == "speech" }.reverse.map { |speech| SpeechText.paragraph_text(speech) }
    end

    private

    def preceding_major_heading_element
      find_previous("major-heading")
    end

    def major_heading
      preceding_major_heading_element.inner_text.strip
    end

    def preceding_minor_heading_element
      find_previous("minor-heading")
    end

    def minor_heading
      preceding_minor_heading_element.inner_text.strip
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

    # The divisions and chair's statements running back from this division to the nearest
    # debate speech or heading, nearest first.
    def run_elements
      elements = []
      element = division_xml.previous_element
      while element&.name&.exclude?("heading")
        break if element.name == "speech" && !chair_statement?(element)

        elements << element
        element = element.previous_element
      end
      elements
    end

    def chair_statement?(speech)
      self.class.chair_statement_text?(speech.text)
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
      SpeechText.speaker_name(speech)
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

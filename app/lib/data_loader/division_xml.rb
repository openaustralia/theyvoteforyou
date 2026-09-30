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

    # Whether a speech is the chair's statement, judged on its plain paragraphs only. Hansard sets
    # the amendments the chair puts in italic inside the chair's own statement, and counted in they
    # made a statement putting eight circulated amendments 8,550 characters long, which the size
    # cap took for a member's speech, so the draft said the question was never recorded. Also used
    # by DivisionSummaryPipeline::EarlierDebate, so the two agree on what the chair says.
    def self.chair_statement?(speech)
      chair_statement_text?(SpeechText.plain_text(speech))
    end

    def self.chair_statement_text?(text)
      text = text.to_s.strip
      text.size <= CHAIR_STATEMENT_MAXIMUM_SIZE && text.match?(CHAIR_STATEMENT)
    end

    # The chair saying the time a limitation of debate (a "guillotine") allotted has run out, in
    # the words Senate Hansard records: "Pursuant to order agreed on 18 August 2026, the time
    # allotted for consideration of 12 bills has expired", "... the time allocated for the
    # remaining stages of this bill has expired". A bill title can hold a full stop ("No. 2"),
    # hence the bounded gap rather than one that stops at the end of a sentence.
    TIME_EXPIRED = /\btime\s+(?:allotted|allocated)\b.{0,300}?\bhas\s+(?:now\s+)?expired\b/im
    # The order being cited, which is what tells a guillotine apart from a debate the standing
    # orders time, such as a matter of urgency. "Pursuant to standing order 75" does not match.
    ORDER_CITED = /\bpursuant\s+to\s+(?:the\s+)?order\b/i
    # How Hansard heads the questions put once a guillotine's time has expired: "Example Bill
    # 2026; Limitation of Debate". Compared with the heading as DebatesXml.normalise_heading gives it.
    LIMITATION_OF_DEBATE_HEADING = /limitation\s+of\s+debate\z/
    # How far into a speech the expiry must be said (see #limitation_expiry?).
    LIMITATION_STATEMENT_OPENING = 400

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

    # The ParlParse ids ("r7339") of the bills this division is about, for finding the same
    # bill's debate under its other headings.
    def bill_ids
      bills.filter_map { |bill| bill[:id].presence }
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
    #
    # Of the chair's statement only the plain paragraphs are returned: the italic ones are the
    # amendments the chair puts, which Hansard incorporates after the question, and their words
    # once decided the route (a sheet that mentioned a select committee settled a vote on eight
    # second reading amendments as establishing one). ContextBuilder then takes the question
    # sentence itself out of what is left (DivisionSummaryPipeline::ChairStatement).
    def operative_question
      nearest_motion_text = pwmotiontexts.last
      return nearest_motion_text.text.strip if nearest_motion_text.present?

      last_speech = previous_speeches.last
      return nil unless last_speech

      plain = SpeechText.plain_text(last_speech) if question_speech
      plain.presence || SpeechText.paragraph_text(last_speech)
    end

    # The chair's statement putting this division's question: the last speech before the
    # division, when it is the chair's (its words say so, or it has no speaker, which is how
    # older files record the chair). Nil when the last speech is a member speaking, which means
    # the question itself was not recorded. Used by the AI summary pipeline to quote the question
    # and say who put it and when.
    def question_speech
      last_speech = previous_speeches.last
      return nil unless last_speech
      return last_speech if last_speech.attr(:nospeaker) == "true" || chair_statement?(last_speech)

      nil
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
    # cannot reach: those before an earlier division under this heading, those under an earlier
    # appearance of the same heading, as when a debate is interrupted by Question Time and
    # resumed under a repeated heading, and those under another heading about the same bill, as
    # when a second reading amendment moved in the "; Second Reading" debate is put under
    # "; Limitation of Debate". DebatesXml#speeches_under_minor_heading does the same for other
    # sitting days.
    def earlier_same_debate_speeches
      title = DebatesXml.normalise_heading(debate_title)
      return [] if title.empty?

      bill_ids = self.bill_ids
      already_read = previous_speeches.map(&:pointer_id)
      division_xml.xpath("preceding::speech").select do |speech|
        next false if already_read.include?(speech.pointer_id)

        DebatesXml.same_debate_section?(DebatesXml.section_heading(speech), title, bill_ids)
      end
    end

    # The chair's statement that a limitation of debate's time has expired, when this division is
    # one of the questions put because it did, or nil. Once the time expires the chair must put
    # the question before the chamber and any other questions needed to conclude proceedings on
    # the bill (Senate Guide No. 17, Debating legislation under time limits), one after another
    # and without debate, so the only speeches beside such a division are the chair's.
    #
    # The statement can be a long way back: after one order's time expired on 20 August 2026 the
    # Senate took 24 divisions on 12 bills, each bill under its own "; Limitation of Debate"
    # heading. So this walks back through what such a run is made of: divisions, sections with
    # that heading (where a minister tabling a document is part of it too), and the chair's
    # statements, which run long when the chair reads out the amendments circulated, so a speech
    # by whoever made the expiry statement counts as one. Anything else between the two is
    # debate or other business, as is any other heading. That, and the statement having to cite
    # the order or sit under that heading, keep a debate the standing orders time from reading
    # as a guillotine. A senator asking by leave to have a vote recorded also stops it, which
    # only leaves the guillotine unmentioned.
    def limitation_of_debate_statement
      others = []
      element = division_xml.previous_element
      while element
        if element.name == "speech" && limitation_expiry?(element)
          return others.all? { |speech| same_speaker?(speech, element) } ? element : nil
        end
        return nil unless limitation_run_continues?(element, others)

        element = element.previous_element
      end
      nil
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
      self.class.chair_statement?(speech)
    end

    # Whether #limitation_of_debate_statement can walk back past this element, noting in others
    # each speech that is not plainly the chair's. Those have to turn out to be the chair's too,
    # so a second speaker among them ends the walk.
    def limitation_run_continues?(element, others)
      case element.name
      when "minor-heading" then limitation_heading?(element)
      when "speech"
        others << element unless chair_statement?(element) || limitation_section?(element)
        others.map { |speech| speech.attr(:speakerid) }.uniq.size <= 1
      else true
      end
    end

    # The chair opens with it ("Minister, please resume your seat. Pursuant to order ..."), and
    # may go straight on to read out the first amendment circulated, so only the opening is read:
    # a length limit would miss that, and a member mentioning the order in passing does not open
    # a speech with it.
    def limitation_expiry?(speech)
      opening = speech.text.to_s.strip[0, LIMITATION_STATEMENT_OPENING]
      opening.match?(TIME_EXPIRED) && (opening.match?(ORDER_CITED) || limitation_section?(speech))
    end

    def limitation_section?(node)
      heading = DebatesXml.section_heading(node)
      heading&.name == "minor-heading" && limitation_heading?(heading)
    end

    def limitation_heading?(heading)
      DebatesXml.normalise_heading(heading.text).match?(LIMITATION_OF_DEBATE_HEADING)
    end

    def same_speaker?(speech, other)
      speech.attr(:speakerid).present? && speech.attr(:speakerid) == other.attr(:speakerid)
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

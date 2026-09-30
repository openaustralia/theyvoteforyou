# frozen_string_literal: true

require "nokogiri"

module DivisionSummaryPipeline
  # Stage 1: assembles the debate context and database facts for one division, as a
  # ContextPacket.
  #
  # Context is gathered at the narrowest tier that works, widening only on demand, because a
  # whole sitting day of Hansard is slow and expensive to send and buries the speeches that
  # actually bear on the vote: :immediate, then :subdebate (the default), then :sitting_day,
  # which the orchestrator asks for when the narrower packet was not enough.
  #
  # This does not re-fetch or re-parse ParlParse XML itself: They Vote For You already has a
  # loader for the same source (app/lib/data_loader/debates.rb, debates_xml.rb, division_xml.rb),
  # used nightly by rake application:load:divisions to build Division records in the first
  # place. A Division's date/number/house/motion are literally the output of parsing the same
  # <division> element this class needs wider context around, so ContextBuilder is a thin
  # adapter over that existing parser rather than a second one (ARCHITECTURE.md section 5).
  #
  # Everything a summary quotes is found here by rule, not by the model: the chair's question,
  # who moved the motion, the words they moved it with and its terms. The model's part comes
  # later and is limited to pointing at units of the Transcript this builds.
  class ContextBuilder
    # House S.O. 133 (Guide p. 58): on Mondays a division called between 10 am and 12 noon is
    # deferred until after 12 noon, and on Tuesdays one called before 2 pm is deferred until
    # after the discussion of the matter of public importance. The Chair then puts all the
    # deferred questions in the order they were deferred, without further debate, so the
    # speeches beside such a division belong to whatever business the chamber had reached.
    #
    # The standing order fixes when the deferral window opens but not how long the run of
    # deferred questions takes, so the hour-long windows below are this code's own conservative
    # estimate of when they are put, not something either guide states. They only raise a
    # warning, so an over-wide window costs a reviewer a look rather than publishing anything.
    DEFERRED_DIVISION_WINDOWS = {
      1 => ("12:00".."12:59"), # Monday, after the 10 am to 12 noon deferral window
      2 => ("16:00".."16:59")  # Tuesday, after the matter of public importance
    }.freeze

    DEFAULT_LEVEL = :subdebate
    DEFAULT_SPEAKER_QUESTION = "The question is that the motion be agreed to."

    # The chair saying a division was deferred, in either chamber's words: "on which a division
    # was called for and deferred", "the division is deferred until ...", "we have a deferred
    # vote on ...". Read from the text because the time-of-day windows below miss deferrals put
    # on other days, such as at the start of the next sitting day.
    DEFERRED_STATEMENT = /standing\s+order\s+133|called\s+for\s+and\s+deferred|(?:division|vote)\s+(?:is|was|be|being|has\s+been)\s+deferred|deferred\s+(?:division|vote|question)/i

    # Question wording that points at something moved earlier, so its terms should be in the
    # packet. Used only to decide whether to look for them. "Stand as printed" decides an
    # amendment to omit part of a bill, which was moved or circulated earlier.
    REFERS_TO_MOVED_BUSINESS = /\bmoved\b|\bamendments?\b|\bmotion\b|\bread\s+a\s+(?:second|third)\s+time\b|
                                \bstand\s+as\s+printed\b/xi

    # xml_fetcher: callable (house, date) returning a parsed ParlParse document or nil, used to
    # read earlier sitting days of the same debate (EarlierDebate). Defaults to the loader's own
    # fetch when this division's XML is fetched too, and to none when xml_content is supplied,
    # so offline fixtures never reach the network.
    # routing: a decision already made for this division. The widened retry passes the first
    # packet's, because routing is about this division and was decided on the speeches beside it;
    # routed again it would read the start of the sitting day, which is some other debate.
    def self.build(division, xml_content: nil, context_level: DEFAULT_LEVEL, xml_fetcher: nil, routing: nil)
      new(division, xml_content: xml_content, context_level: context_level, xml_fetcher: xml_fetcher,
                    routing: routing).build
    end

    def initialize(division, xml_content: nil, context_level: DEFAULT_LEVEL, xml_fetcher: nil, routing: nil)
      @division = division
      @facts = DivisionFacts.from(division)
      @xml_content = xml_content
      @context_level = context_level
      @xml_fetcher = xml_fetcher
      @routing = routing
    end

    def build
      matched_division_xml = find_matching_division_xml
      return build_from_division_record unless matched_division_xml

      build_from_matched_division(matched_division_xml)
    end

    private

    attr_reader :division, :facts, :xml_content, :context_level

    def xml_fetcher
      return @xml_fetcher if @xml_fetcher
      return nil if xml_content.present? || !defined?(DataLoader::Debates)

      ->(house, date) { DataLoader::Debates.fetch_xml_document(house, date) }
    end

    # Finds the DataLoader::DivisionXml (the same wrapper the nightly loader parses this
    # division's date/number/motion out of) that corresponds to this division, or nil if no
    # Hansard XML is available or none of its <division> elements match. Matches by divnumber
    # first, since that's the identity DataLoader::Debates itself keys Division records on
    # (find_or_initialize_by(date:, number:, house:)); clock time and debate_gid are only
    # fallbacks for the rare case a division number is missing or ambiguous in the source.
    def find_matching_division_xml
      doc = parse_document
      return nil unless doc

      division_xmls = DataLoader::DebatesXml.new(doc, facts.house).divisions
      return nil if division_xmls.empty?

      time = ClockTime.normalise(facts.clock_time)
      division_xmls.find { |d| facts.number.positive? && d.number.to_i == facts.number } ||
        division_xmls.find { |d| time.present? && ClockTime.normalise(d.clock_time) == time } ||
        division_xmls.find { |d| facts.debate_gid.present? && d.debate_gid == facts.debate_gid }
    rescue StandardError => e
      Rails.logger.warn "DivisionSummaryPipeline::ContextBuilder could not parse Hansard XML for #{facts.house} #{facts.date}: #{e.message}" if defined?(Rails)
      nil
    end

    # Swallows fetch and parse failures into nil so #build degrades to the Division-record
    # fallback. A summariser run that dies because Hansard was briefly unreachable would be
    # worse than one that produces a thinner draft and says so.
    def parse_document
      return Nokogiri::XML(xml_content) if xml_content.present?
      return nil if facts.house.blank? || facts.date.blank?
      return nil unless defined?(DataLoader::Debates)

      DataLoader::Debates.fetch_xml_document(facts.house, facts.date)
    rescue StandardError
      nil
    end

    def build_from_matched_division(division_xml)
      heading = division_xml.name.to_s
      speeches = division_xml.context_speeches(context_level)
      question_speech_id = division_xml.question_speech&.attr(:id)
      chair = chair_statement(speeches, question_speech_id)
      speaker_question = chair&.question || division_xml.operative_question.presence || DEFAULT_SPEAKER_QUESTION
      deferred = deferred_by_chair?(division_xml, speeches)
      earlier = earlier_debate(division_xml, chair&.putting_text.presence || speaker_question, speeches, deferred)
      earlier_speeches = earlier.speeches.reject { |speech| speeches.any? { |s| s[:id] == speech[:id] } }
      mover = MoverFinder.find(question: speaker_question, putting: chair&.putting_text,
                               speeches: earlier_speeches + speeches, house: facts.house, date: facts.date,
                               circulated: chair&.circulated_by.present?)
      earlier_speeches = without_other_stages(earlier_speeches, mover)
      transcript = Transcript.build(heading: heading, speeches: speeches, earlier_speeches: earlier_speeches,
                                    question_speech_id: question_speech_id, chair_statement: chair)
      limitation = limitation_statement(division_xml)
      warnings = context_warnings(division_xml, speeches, earlier_speeches, deferred: deferred, limitation: limitation)

      assemble_packet(
        heading: heading, speaker_question: speaker_question, transcript: transcript, mover: mover,
        routing: route(speaker_question, heading, transcript, motion_text: mover&.moved_text),
        context_warnings: warnings, source: :hansard_xml, division_xml_id: division_xml.division_xml.attr(:id),
        limitation_statement: limitation, circulation: circulation(chair, transcript, mover)
      )
    end

    # Amendments the chair put that nobody moved in the chamber: the chair's statement prints their
    # terms or says who circulated them, and no move of them was found. Under a limitation of debate
    # that is how circulated amendments are decided (Senate Guide No. 17; House S.O. 85(c)).
    def circulation(chair, transcript, mover)
      return nil unless chair

      by = chair.circulated_by
      return nil unless by || transcript.question_terms_units.any?

      speech = transcript.speech_with_id(mover&.speech&.dig(:id))
      return nil if speech && transcript.last_move_units(speech, :motion).any?

      Circulation.new(by: by, member: circulating_member(by), plural: chair.plural?)
    end

    # The member who circulated them, when Hansard names one fully: a surname alone ("Senator
    # Cadell") does not identify a member reliably, so it is left as Hansard gives it.
    def circulating_member(by)
      resolved = if (match = by.to_s.match(/\Athe\s+(?:honourable\s+)?member\s+for\s+(.+)\z/))
                   MemberResolver.resolve(electorate: match[1], house: facts.house_key, date: facts.date.presence)
                 elsif (match = by.to_s.match(/\ASenator\s+(\S+(?:\s+\S+)+)\z/)) && by.exclude?(" and ")
                   MemberResolver.resolve(name: match[1], house: facts.house_key, date: facts.date.presence)
                 end
      resolved&.member ? resolved : nil
    end

    # The chair's statement putting this division's question, which is the last speech before the
    # division when there is one. The question the division decided is its last question sentence
    # (ChairStatement#question), and that is what Stage 2 routes on: a lead-in before it once
    # fenced a remaining stages question as an amendment (KNOWN_ISSUES.md KI-35), and amendments
    # incorporated after it once settled a route. MoverFinder reads the paragraphs that put the
    # question, since the chair often names the mover in a sentence of its own.
    def chair_statement(speeches, question_speech_id)
      speech = speeches.last
      return nil unless question_speech_id.present? && speech && speech[:id] == question_speech_id

      ChairStatement.new(speech[:paragraphs])
    end

    # A speech EarlierDebate found under another of the bill's headings stays in the packet only
    # when it is the move the chair named. Any other is a different stage's business: the
    # extractor could quote it as the explanation, and with no mover found the validator cannot
    # tell whose words it is looking at.
    def without_other_stages(earlier_speeches, mover)
      earlier_speeches.reject { |speech| speech[:other_heading] && speech[:id] != mover&.speech&.dig(:id) }
    end

    # The chair saying a limitation of debate's time had expired, when this division is one of
    # the questions then put without debate (DataLoader::DivisionXml#limitation_of_debate_statement),
    # cut to the sentence that says so: the rest of the statement usually puts the first question,
    # which may be on another bill. The sentence is Hansard's own text, found by rule.
    def limitation_statement(division_xml)
      node = division_xml.limitation_of_debate_statement
      return nil unless node

      speech = DataLoader::SpeechText.context_speech(node)
      sentences = speech[:paragraphs].pluck(:text).flat_map do |paragraph|
        Transcript.sentence_spans(paragraph).map { |start, finish| paragraph[start...finish] }
      end
      sentence = sentences.find { |text| text.match?(DataLoader::DivisionXml::TIME_EXPIRED) }
      speech.slice(:id, :speaker, :speaker_gid, :time).merge(text: sentence || speech[:text])
    end

    # The rest of this division's own debate, when the motion it decides is not in the speeches
    # beside it (EarlierDebate explains when that happens). Skipped when a speech in front of the
    # division already moves something and the chair is not describing a deferred question, so
    # the common case costs nothing. The sitting-day retry always looks, because the narrower
    # packet has already proved not to be enough. putting is the chair's words putting the
    # question, whose lead-in often says what it refers to ("I'll first deal with the amendments
    # moved by Senator Example on sheet 3832. The question is that part 4 ... stand as printed.").
    def earlier_debate(division_xml, putting, speeches, deferred)
      empty = EarlierDebate::Result.new(speeches: [], dates: [])
      moved_here = speeches.any? { |s| s[:moved_text].present? }
      wanted = context_level == :sitting_day || deferred ||
               (!moved_here && putting.to_s.match?(REFERS_TO_MOVED_BUSINESS))
      return empty unless wanted

      EarlierDebate.collect(division_xml: division_xml, house: facts.house, date: facts.date,
                            fetcher: xml_fetcher, exhaustive: context_level == :sitting_day)
    rescue StandardError => e
      Rails.logger.warn "DivisionSummaryPipeline::ContextBuilder could not gather earlier debate: #{e.message}" if defined?(Rails)
      empty
    end

    # Whether the chair says this division was deferred, in the speeches beside it or anywhere
    # in the run of divisions it belongs to: only the first question of a deferred run says so
    # (DataLoader::DivisionXml#run_statements).
    def deferred_by_chair?(division_xml, speeches)
      (speeches.map { |s| s[:text].to_s } + division_xml.run_statements).any? { |text| text.match?(DEFERRED_STATEMENT) }
    end

    # Stage 1 takes the speeches immediately before the <division> element, which assumes the
    # debate next to a division is the debate about it. Two procedures break that assumption in
    # a knowable way, so the packet says when it may be looking at the wrong debate rather than
    # letting the extractor treat unrelated speeches as the argument for this vote
    # (KNOWN_ISSUES.md, KI-6). This is the same class of trap as the "Limitation of Debate"
    # heading: usually right, silently wrong in cases the standing orders spell out.
    #
    # These are warnings, not errors. Detecting the risk is cheap and reliable; recovering the
    # right debate is neither, so the judgement is handed to the extractor (which can report
    # missing evidence) and then to a reviewer.
    def context_warnings(division_xml, speeches, earlier_speeches, deferred:, limitation: nil)
      warnings = []

      if limitation
        warnings << "The chair put this question under a limitation of debate (a 'guillotine'): at " \
                    "#{ClockTime.display(limitation[:time])} the chair said the time allotted had expired, and the " \
                    "questions still to be decided were then put one after another without further debate. Any " \
                    "debate about this question took place before that."
      end

      if division_xml.preceded_by_division?
        warnings << "This division immediately follows another with no debate between them. Where divisions " \
                    "are taken successively only the first has the debate about it in front of it, so the " \
                    "debate about this question may be before the earlier division."
      end

      warnings << "No debate speeches were found immediately before this division." if speeches.empty?

      deferred_warning = deferred_division_warning(speeches, deferred_by_chair: deferred)
      warnings << deferred_warning if deferred_warning

      if earlier_speeches.any?
        dates = earlier_speeches.pluck(:date).uniq
        where = "earlier in the same debate"
        where += " or another stage of the same bill" if earlier_speeches.any? { |speech| speech[:other_heading] }
        warnings << "The motion this division decides was not moved in the speeches beside it, so the packet " \
                    "adds the speeches from #{where} (#{dates.join(', ')}) that moved something or put a " \
                    "question. Check they are about the same question."
      end

      warnings
    end

    # Said outright by the chair where Hansard records it, and otherwise inferred from the
    # House's deferral windows. A motion moved inside the window was put there and then, so the
    # window alone is no reason to doubt the speeches beside it.
    def deferred_division_warning(speeches, deferred_by_chair:)
      if deferred_by_chair
        return "The chair's words show this division was deferred, and a deferred question is put without " \
               "further debate, so the debate about it took place earlier than the speeches beside it."
      end
      return nil if facts.senate?

      window = DEFERRED_DIVISION_WINDOWS[weekday]
      time = ClockTime.normalise(facts.clock_time)
      return nil unless window&.cover?(time)
      return nil if speeches.any? { |s| s[:moved_text].present? && window.cover?(ClockTime.normalise(s[:time])) }

      "This division was taken in the part of the day when the House puts questions whose divisions were " \
        "deferred earlier (Standing Order 133). A deferred question is put without further debate, so the " \
        "speeches in this excerpt may be about different business altogether."
    end

    def weekday
      Date.parse(facts.date).wday
    rescue ArgumentError, TypeError
      nil
    end

    # Fallback when Hansard XML is unavailable or no <division> in it matches: uses the
    # Division record's own motion/name, which is a real but partial signal ("division.motion"
    # can already contain the preceding speeches DataLoader::DivisionXml#motion fell back to at
    # load time). The motion can still be quoted, but only if the model points at it in this
    # text, since nothing here says which lines are the motion.
    def build_from_division_record
      motion_text = record_motion_text

      # Stage 2 routes entirely on this sentence, so it is worth reconstructing from the
      # stored motion rather than defaulting: a wrong or absent question misroutes the vote.
      speaker_question = if motion_text =~ /The (?:immediate )?question is that.*?(?:\.|\n|\z)/i
                           Regexp.last_match(0).strip
                         elsif motion_text =~ /That .*/i
                           "The question is that #{Regexp.last_match(0).sub(/\AThat\s+/i, '')}"
                         else
                           DEFAULT_SPEAKER_QUESTION
                         end

      transcript = Transcript.from_record(heading: facts.name, text: motion_text)
      assemble_packet(
        heading: facts.name, speaker_question: speaker_question, transcript: transcript, mover: nil,
        routing: route(speaker_question, facts.name, transcript),
        context_warnings: ["No Hansard XML was available for this division, so this packet was built from the " \
                           "Division record's own stored motion text and carries no surrounding debate."],
        source: :division_record, division_xml_id: nil, limitation_statement: nil
      )
    end

    def record_motion_text
      stored = if division.is_a?(Hash)
                 facts[:original_motion].presence || facts[:motion]
               else
                 division.original_motion.presence || division.motion
               end
      TextNormaliser.strip_xml_markup(stored.to_s)
    end

    # Stage 2 runs here rather than in the orchestrator so a packet is never in circulation
    # without its routing decision attached.
    def route(speaker_question, heading, transcript, motion_text: nil)
      @routing || ProceduralRouter.route(
        speaker_question: speaker_question,
        chamber: facts.house,
        debate_heading: heading,
        hansard_snippet: transcript.opening_text,
        motion_text: motion_text.to_s.split(/\n{2,}/).first.to_s
      )
    end

    def assemble_packet(heading:, speaker_question:, transcript:, mover:, routing:, context_warnings:, source:,
                        division_xml_id:, limitation_statement:, circulation: nil)
      ContextPacket.new(facts: facts, heading: heading, speaker_question: speaker_question, transcript: transcript,
                        mover: mover, routing: routing, context_level: context_level,
                        context_warnings: context_warnings, source: source, division_xml_id: division_xml_id,
                        limitation_statement: limitation_statement, circulation: circulation)
    end
  end
end

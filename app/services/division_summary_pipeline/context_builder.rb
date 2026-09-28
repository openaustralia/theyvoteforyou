# frozen_string_literal: true

require "nokogiri"

module DivisionSummaryPipeline
  # The one object every later stage reads from. Stages 3 to 5 see only this, never the
  # Division or the XML, so whatever is missing here cannot be recovered downstream.
  ContextPacket = Struct.new(
    :division_id,
    :date,
    :house,
    :clock_time,
    :speaker_question,
    :hansard_context,
    :debate_heading,
    :division_metadata,
    :official_summary,
    :context_level,
    :procedural_decision,
    :extra_context,
    :context_warnings,
    :mover,
    :earlier_debate_dates,
    keyword_init: true
  )

  # Stage 1: assembles the debate context and database facts for one division.
  #
  # Context is gathered at the narrowest tier that works, widening only on demand, because a
  # whole sitting day of Hansard is slow and expensive to send and buries the speeches that
  # actually bear on the vote: :immediate, then :subdebate (the default), then :sitting_day,
  # which the orchestrator asks for only when the extractor reports the narrower packet was
  # not enough.
  #
  # This does not re-fetch or re-parse ParlParse XML itself: They Vote For You already has a
  # loader for the same source (app/lib/data_loader/debates.rb, debates_xml.rb, division_xml.rb),
  # used nightly by rake application:load:divisions to build Division records in the first
  # place. A Division's date/number/house/motion are literally the output of parsing the same
  # <division> element this class needs wider context around, so ContextBuilder is a thin
  # adapter over that existing parser rather than a second one - see ARCHITECTURE.md in this
  # directory for the full reasoning. The only genuinely new parsing surface this feature
  # needed (the operative question text, and speeches gathered at progressive context tiers)
  # was added directly to DataLoader::DivisionXml as additive public methods.
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
    # packet. Used only to decide whether to look for them.
    REFERS_TO_MOVED_BUSINESS = /\bmoved\b|\bamendments?\b|\bmotion\b|\bread\s+a\s+(?:second|third)\s+time\b/i

    # xml_fetcher: callable (house, date) returning a parsed ParlParse document or nil, used to
    # read earlier sitting days of the same debate (EarlierDebate). Defaults to the loader's own
    # fetch when this division's XML is fetched too, and to none when xml_content is supplied,
    # so offline fixtures never reach the network.
    def self.build(division, xml_content: nil, context_level: DEFAULT_LEVEL, extra_context: nil, xml_fetcher: nil)
      new(division, xml_content: xml_content, context_level: context_level, extra_context: extra_context,
                    xml_fetcher: xml_fetcher).build
    end

    def initialize(division, xml_content: nil, context_level: DEFAULT_LEVEL, extra_context: nil, xml_fetcher: nil)
      @division = division
      @xml_content = xml_content
      @context_level = context_level
      @extra_context = extra_context
      @xml_fetcher = xml_fetcher
    end

    def build
      matched_division_xml = find_matching_division_xml
      return build_from_division_fallback unless matched_division_xml

      build_from_matched_division(matched_division_xml)
    end

    private

    attr_reader :division, :xml_content, :context_level, :extra_context

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

      division_xmls = DataLoader::DebatesXml.new(doc, division_house).divisions
      return nil if division_xmls.empty?

      div_num = division_number
      matched = division_xmls.find { |d| div_num.positive? && d.number.to_i == div_num }
      matched ||= division_xmls.find { |d| division_clock_time.present? && normalise_time(d.clock_time) == normalise_time(division_clock_time) }
      matched ||= division_xmls.find { |d| division_debate_gid.present? && d.debate_gid == division_debate_gid }
      matched
    rescue StandardError => e
      Rails.logger.warn "DivisionSummaryPipeline::ContextBuilder could not parse Hansard XML for #{division_house} #{division_date}: #{e.message}" if defined?(Rails)
      nil
    end

    # Swallows fetch and parse failures into nil so #build degrades to the Division-record
    # fallback. A summariser run that dies because Hansard was briefly unreachable would be
    # worse than one that produces a thinner draft and says so.
    def parse_document
      return Nokogiri::XML(xml_content) if xml_content.present?
      return nil if division_house.blank? || division_date.blank?
      return nil unless defined?(DataLoader::Debates)

      DataLoader::Debates.fetch_xml_document(division_house, division_date)
    rescue StandardError
      nil
    end

    # The "SPEECH: <speaker>:" prefix on each speech is a contract with stage 4, not
    # formatting: ProvenanceValidator.extract_speaker_text splits on those markers to verify
    # a quote against the member it was attributed to. Drop the tagging and a genuine quote
    # from one member silently passes as another's.
    #
    # hansard_context holds Hansard text and nothing else, because stage 4 treats every word of
    # it as something a member said. The extractor's own missing_context_clue from a first
    # pass travels separately, as packet.extra_context, for the same reason.
    def build_from_matched_division(division_xml)
      speaker_q = division_xml.operative_question.presence || DEFAULT_SPEAKER_QUESTION
      heading = division_xml.name.to_s
      speeches = division_xml.context_speeches(context_level)
      deferred = deferred_by_chair?(division_xml, speeches)
      earlier = earlier_debate(division_xml, speaker_q, speeches, deferred)
      mover = MoverFinder.find(question: speaker_q, speeches: earlier.speeches + speeches,
                               house: division_house, date: division_date)

      lines = []
      lines << "DEBATE: #{TextNormaliser.clean_text(heading)}" if heading.present?
      lines << ""
      unless earlier.empty?
        lines << "EARLIER IN THIS DEBATE (only the speeches that moved something or put a question, " \
                 "from #{earlier.dates.join(', ')}):"
        earlier.speeches.each { |speech| lines << speech_block(speech, dated: true) }
        lines << "THE SPEECHES BEFORE THIS DIVISION:"
      end
      speeches.each { |speech| lines << speech_block(speech) }

      time_str = division_xml.clock_time.presence || division_clock_time
      lines << "DIVISION [#{time_str}]"

      hansard_context = lines.join("\n")

      assemble_packet(
        speaker_question: speaker_q,
        hansard_context: hansard_context,
        debate_heading: heading,
        procedural_decision: route(speaker_q, heading, hansard_context, motion_text: mover&.moved_text),
        context_warnings: context_warnings(division_xml, speeches, earlier, deferred: deferred),
        mover: mover,
        earlier_debate_dates: earlier.dates
      )
    end

    def speech_block(speech, dated: false)
      label = speech[:speaker].presence || "Member"
      stamp = [(speech[:date] if dated), speech[:time].presence].compact.join(" ")
      label += " [#{stamp}]" if stamp.present?
      "SPEECH: #{label}:\n#{TextNormaliser.clean_text(speech[:text])}\n"
    end

    # The rest of this division's own debate, when the motion it decides is not in the speeches
    # beside it (EarlierDebate explains when that happens). Skipped when a speech in front of the
    # division already moves something and the chair is not describing a deferred question, so
    # the common case costs nothing. The sitting-day retry always looks, because the extractor
    # has already said the narrower packet was not enough.
    def earlier_debate(division_xml, speaker_question, speeches, deferred)
      empty = EarlierDebate::Result.new(speeches: [], dates: [])
      moved_here = speeches.any? { |s| s[:moved_text].present? }
      wanted = context_level == :sitting_day || deferred ||
               (!moved_here && speaker_question.to_s.match?(REFERS_TO_MOVED_BUSINESS))
      return empty unless wanted

      EarlierDebate.collect(division_xml: division_xml, house: division_house, date: division_date,
                            fetcher: xml_fetcher, exhaustive: context_level == :sitting_day)
    rescue StandardError => e
      Rails.logger.warn "DivisionSummaryPipeline::ContextBuilder could not gather earlier debate: #{e.message}" if defined?(Rails)
      empty
    end

    # Whether the chair says this division was deferred, in the speeches beside it or anywhere
    # in the run of divisions it belongs to: only the first question of a deferred run says so
    # (DataLoader::DivisionXml#run_statements).
    def deferred_by_chair?(division_xml, speeches)
      run = division_xml.respond_to?(:run_statements) ? division_xml.run_statements : []
      (speeches.map { |s| s[:text].to_s } + run).any? { |text| text.match?(DEFERRED_STATEMENT) }
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
    # insufficient context) and then to a reviewer.
    def context_warnings(division_xml, speeches, earlier = nil, deferred: false)
      warnings = []

      if division_xml.respond_to?(:preceded_by_division?) && division_xml.preceded_by_division?
        warnings << "This division immediately follows another with no debate between them. Where divisions " \
                    "are taken successively only the first has the debate about it in front of it, so the " \
                    "debate about this question may be before the earlier division."
      end

      warnings << "No debate speeches were found immediately before this division." if speeches.empty?

      deferred_warning = deferred_division_warning(speeches, deferred_by_chair: deferred)
      warnings << deferred_warning if deferred_warning

      if earlier.present?
        warnings << "The motion this division decides was not moved in the speeches beside it, so the packet " \
                    "adds the speeches from earlier in the same debate (#{earlier.dates.join(', ')}) that moved " \
                    "something or put a question. Check they are about the same question."
      end

      warnings
    end

    # Said outright by the chair where Hansard records it, and otherwise inferred from the
    # House's deferral windows. A motion moved inside the window was put there and then, so the
    # window alone is no reason to doubt the speeches beside it.
    def deferred_division_warning(speeches = [], deferred_by_chair: false)
      if deferred_by_chair
        return "The chair's words show this division was deferred, and a deferred question is put without " \
               "further debate, so the debate about it took place earlier than the speeches beside it."
      end
      return nil unless division_house.include?("representative")

      date = begin
        Date.parse(division_date)
      rescue ArgumentError, TypeError
        nil
      end
      return nil unless date

      window = DEFERRED_DIVISION_WINDOWS[date.wday]
      return nil unless window

      time = normalise_time(division_clock_time)
      return nil unless time.match?(/\A\d\d:\d\d\z/) && window.cover?(time)
      return nil if speeches.any? { |s| s[:moved_text].present? && window.cover?(normalise_time(s[:time])) }

      "This division was taken in the part of the day when the House puts questions whose divisions were " \
        "deferred earlier (Standing Order 133). A deferred question is put without further debate, so the " \
        "speeches in this excerpt may be about different business altogether."
    end

    # Fallback when Hansard XML is unavailable or no <division> in it matches: uses the
    # Division record's own motion/name, which is a real but partial signal (see
    # ARCHITECTURE.md (same directory) - "division.motion" can already contain the
    # preceding speeches DataLoader::DivisionXml#motion fell back to at load time).
    def build_from_division_fallback
      motion_text = if division.respond_to?(:original_motion) && division.original_motion.present?
                      TextNormaliser.strip_xml_markup(division.original_motion)
                    elsif division.respond_to?(:motion)
                      TextNormaliser.clean_text(division.motion)
                    else
                      ""
                    end

      # Stage 2 routes entirely on this sentence, so it is worth reconstructing from the
      # stored motion rather than defaulting: a wrong or absent question misroutes the vote.
      speaker_q = if motion_text =~ /The (?:immediate )?question is that.*?(?:\.|\n|\z)/i
                    Regexp.last_match(0).strip
                  elsif motion_text =~ /That .*/i
                    "The question is that #{Regexp.last_match(0).sub(/\AThat\s+/i, '')}"
                  else
                    DEFAULT_SPEAKER_QUESTION
                  end

      heading = division_name
      hansard_context = "DEBATE: #{TextNormaliser.clean_text(heading)}\n\nMOTION:\n#{motion_text}"

      assemble_packet(
        speaker_question: speaker_q,
        hansard_context: hansard_context,
        debate_heading: heading,
        procedural_decision: route(speaker_q, heading, hansard_context),
        context_warnings: ["No Hansard XML was available for this division, so this packet was built from the " \
                           "Division record's own stored motion text and carries no surrounding debate."]
      )
    end

    # Stage 2 runs here rather than in the orchestrator so a packet is never in circulation
    # without its routing decision attached.
    def route(speaker_question, heading, hansard_context, motion_text: nil)
      ProceduralRouter.route(
        speaker_question: speaker_question,
        chamber: division_house,
        debate_heading: heading,
        hansard_snippet: hansard_context.to_s[0..1000],
        motion_text: motion_text.to_s.split(/\n{2,}/).first.to_s
      )
    end

    # Counts, dates and times come from the Division record, never from the XML and never
    # from the model: they are Type 1 authoritative facts (ARCHITECTURE.md, Data
    # classification) that stage 5 publishes as given.
    def assemble_packet(speaker_question:, hansard_context:, debate_heading:, procedural_decision:,
                        context_warnings: [], mover: nil, earlier_debate_dates: [])
      metadata = {
        tvfy_id: division_id,
        house: division_house,
        date: division_date,
        number: division_number,
        clock_time: division_clock_time,
        name: division_name,
        aye_votes: division_aye_votes,
        no_votes: division_no_votes,
        rebellions: division_rebellions
      }

      ContextPacket.new(
        division_id: division_id,
        date: division_date,
        house: division_house,
        clock_time: division_clock_time,
        speaker_question: speaker_question,
        hansard_context: hansard_context,
        debate_heading: debate_heading,
        division_metadata: metadata,
        official_summary: nil,
        context_level: context_level,
        procedural_decision: procedural_decision,
        extra_context: extra_context,
        context_warnings: context_warnings,
        mover: mover,
        earlier_debate_dates: earlier_debate_dates
      )
    end

    # Division attribute readers supporting both ActiveRecord Division records and the
    # plain Hashes used by the parliamentary evaluation fixtures (spec/fixtures/
    # division_summaries) - see spec/services/division_summary_pipeline/evaluation_spec.rb.
    def division_id
      division.respond_to?(:id) ? division.id : (division[:id] || division["id"])
    end

    def division_date
      division.respond_to?(:date) ? division.date.to_s : (division[:date] || division["date"]).to_s
    end

    def division_house
      division.respond_to?(:house) ? division.house.to_s : (division[:house] || division["house"]).to_s
    end

    def division_number
      division.respond_to?(:number) ? division.number.to_i : (division[:number] || division["number"]).to_i
    end

    def division_clock_time
      division.respond_to?(:clock_time) ? division.clock_time.to_s : (division[:clock_time] || division["clock_time"]).to_s
    end

    def division_name
      division.respond_to?(:name) ? division.name.to_s : (division[:name] || division["name"]).to_s
    end

    def division_debate_gid
      division.respond_to?(:debate_gid) ? division.debate_gid.to_s : (division[:debate_gid] || division["debate_gid"]).to_s
    end

    def division_aye_votes
      if division.respond_to?(:aye_votes_including_tells)
        division.aye_votes_including_tells
      elsif division.respond_to?(:aye_votes)
        division.aye_votes
      else
        division[:aye_votes] || division["aye_votes"] || 0
      end
    end

    def division_no_votes
      if division.respond_to?(:no_votes_including_tells)
        division.no_votes_including_tells
      elsif division.respond_to?(:no_votes)
        division.no_votes
      else
        division[:no_votes] || division["no_votes"] || 0
      end
    end

    def division_rebellions
      if division.respond_to?(:rebellions)
        division.rebellions
      else
        division[:rebellions] || division["rebellions"] || 0
      end
    end

    # Hansard records the same moment as both "12:30 PM" and "12:30", so times are only
    # comparable once flattened. Used for matching a division, never for published text.
    def normalise_time(time_str)
      return "" if time_str.blank?

      s = time_str.to_s.strip.upcase
      if s =~ /(\d{1,2}):(\d{2})\s*([AP]M)/
        h = Regexp.last_match(1).to_i
        m = Regexp.last_match(2).to_i
        mer = Regexp.last_match(3)
        h += 12 if mer == "PM" && h != 12
        h = 0 if mer == "AM" && h == 12
        format("%02d:%02d", h, m)
      elsif s =~ /(\d{1,2}):(\d{2})/
        format("%02d:%02d", Regexp.last_match(1).to_i, Regexp.last_match(2).to_i)
      else
        s
      end
    end
  end
end

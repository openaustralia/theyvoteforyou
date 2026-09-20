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
    DEFAULT_LEVEL = :subdebate
    DEFAULT_SPEAKER_QUESTION = "The question is that the motion be agreed to."

    def self.build(division, xml_content: nil, context_level: DEFAULT_LEVEL, extra_context: nil)
      new(division, xml_content: xml_content, context_level: context_level, extra_context: extra_context).build
    end

    def initialize(division, xml_content: nil, context_level: DEFAULT_LEVEL, extra_context: nil)
      @division = division
      @xml_content = xml_content
      @context_level = context_level
      @extra_context = extra_context
    end

    def build
      matched_division_xml = find_matching_division_xml
      return build_from_division_fallback unless matched_division_xml

      build_from_matched_division(matched_division_xml)
    end

    private

    attr_reader :division, :xml_content, :context_level, :extra_context

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
    def build_from_matched_division(division_xml)
      speaker_q = division_xml.operative_question.presence || DEFAULT_SPEAKER_QUESTION
      heading = division_xml.name.to_s
      speeches = division_xml.context_speeches(context_level)

      lines = []
      lines << "DEBATE: #{heading}" if heading.present?
      lines << ""

      speeches.each do |speech|
        label = speech[:speaker].presence || "Member"
        label += " [#{speech[:time]}]" if speech[:time].present?
        lines << "SPEECH: #{label}:\n#{TextNormaliser.clean_text(speech[:text])}\n"
      end

      time_str = division_xml.clock_time.presence || division_clock_time
      lines << "DIVISION [#{time_str}]"
      lines << "\nPRIOR_DEBATE_CONTEXT:\n#{extra_context.strip}" if extra_context.present?

      hansard_context = lines.join("\n")

      assemble_packet(
        speaker_question: speaker_q,
        hansard_context: hansard_context,
        debate_heading: heading,
        procedural_decision: route(speaker_q, heading, hansard_context)
      )
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
      hansard_context = "DEBATE: #{heading}\n\nMOTION:\n#{motion_text}"
      hansard_context += "\n\nPRIOR_DEBATE_CONTEXT:\n#{extra_context.strip}" if extra_context.present?

      assemble_packet(
        speaker_question: speaker_q,
        hansard_context: hansard_context,
        debate_heading: heading,
        procedural_decision: route(speaker_q, heading, hansard_context)
      )
    end

    # Stage 2 runs here rather than in the orchestrator so a packet is never in circulation
    # without its routing decision attached.
    def route(speaker_question, heading, hansard_context)
      ProceduralRouter.route(
        speaker_question: speaker_question,
        chamber: division_house,
        debate_heading: heading,
        hansard_snippet: hansard_context.to_s[0..1000]
      )
    end

    # Counts, dates and times come from the Division record, never from the XML and never
    # from the model: they are Type 1 authoritative facts (ARCHITECTURE.md, Data
    # classification) that stage 5 publishes as given.
    def assemble_packet(speaker_question:, hansard_context:, debate_heading:, procedural_decision:)
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
        extra_context: extra_context
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

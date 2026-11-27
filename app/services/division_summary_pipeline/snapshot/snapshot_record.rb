# frozen_string_literal: true

require "digest"

module DivisionSummaryPipeline
  # One division's block in the routing snapshot (rake ai:route_snapshot, RouteSnapshot): what
  # Stage 2 decided and everything Stage 1 found by rule, read from the ContextPacket, after the
  # sources RouteSnapshot adds (the Parliament, the version of the day's Hansard and the days
  # Stage 1 read). Two runs of the same code on the same Hansard give the same block, and any
  # change shows as a changed line in a diff: keys in a fixed order, no database ids, and long text
  # cut to its two ends with a hash of the whole. How to read a block:
  # spec/route_snapshots/README.md.
  #
  # The facts are only those Hansard itself records (counts, result, bills). Figures the database
  # derives later, such as rebellions, are left out, so a change to them never shows up as a change
  # in what Stages 1 and 2 decided.
  class SnapshotRecord
    # Text of more than twice this many words is shown as its first and last this-many words, its
    # word count and a hash of the whole, so a change anywhere in it still changes the line.
    LONG_TEXT_ENDS = 20
    HASH_LENGTH = 12

    def self.build(packet, sources = {})
      new(packet, sources).to_h
    end

    # The block's name: house, date and number, which are the same in every copy of the database,
    # unlike the record's id.
    def self.key(division)
      "#{division.house}_#{division.date}_#{division.number}"
    end

    def self.shorten_text(text)
      words = text.split
      return text if words.size <= LONG_TEXT_ENDS * 2

      "#{words.first(LONG_TEXT_ENDS).join(' ')} ... (#{words.size} words) ... " \
        "#{words.last(LONG_TEXT_ENDS).join(' ')} [hash: #{Digest::SHA256.hexdigest(text)[0, HASH_LENGTH]}]"
    end

    def initialize(packet, sources = {})
      @packet = packet
      @sources = sources
    end

    def to_h
      block = {
        "facts" => facts, **sources, "hansard_division" => packet.division_xml_id, "source" => packet.source.to_s,
        "heading" => packet.heading, "context_level" => packet.context_level.to_s, "route" => route,
        "question" => question, "motion" => motion, "mover" => mover, "circulation" => circulation,
        "proposer" => packet.proposer && { "name" => packet.proposer.name, "party" => packet.proposer.party },
        "closed_template" => packet.closed_template_id, "followup" => packet.facts.supplied[:followup_link],
        "speeches" => speeches, "earlier_debate" => packet.earlier_debate_dates.map(&:to_s),
        "limitation" => limitation, "warnings" => packet.context_warnings
      }
      shorten(block)
    end

    private

    attr_reader :packet, :sources

    delegate :transcript, to: :packet

    def facts
      facts = packet.facts
      {
        "house" => facts.house, "date" => facts.date, "number" => facts.number,
        "time" => ClockTime.normalise(facts.clock_time).presence, "result" => facts.result, "tied" => facts.tied,
        "ayes" => facts.aye_votes, "noes" => facts.no_votes, "bills" => facts.bill_titles
      }
    end

    def route
      routing = packet.routing
      {
        "mode" => routing.mode.to_s, "template" => routing.template_id, "allowed" => routing.allowed_templates,
        "forbidden" => routing.forbidden_templates, "rule" => routing.rule_name.to_s, "reason" => routing.reason
      }
    end

    def question
      speech = transcript.question_speech
      {
        "routed_on" => packet.speaker_question, "chair_statement" => text_of(transcript.question_units),
        "put_by" => speech&.speaker, "time" => ClockTime.normalise(speech&.time).presence,
        "divided" => ChairStatement.divided_parts(packet.speaker_question),
        "by_reference" => packet.question_by_reference?, "states_motion" => packet.question_states_motion?
      }
    end

    # The terms the division decided, as Stage 1 found them: moved in the mover's speech, or printed
    # in the chair's statement when amendments circulated beforehand were put without being moved.
    def motion
      speech = packet.mover_speech
      moved = speech ? transcript.last_move_units(speech, :motion) : []
      printed = transcript.question_terms_units
      {
        "found" => packet.motion_found?, "found_in" => motion_found_in(moved, printed),
        "terms_moved" => packet.terms_moved?,
        "introduction" => (text_of(transcript.last_move_units(speech, :move)) if speech),
        "text" => text_of(moved.presence || printed)
      }
    end

    def motion_found_in(moved, printed)
      if moved.any? then "mover_speech"
      elsif printed.any? then "chair_statement"
      end
    end

    def mover
      found = packet.mover
      return nil unless found

      speech = found.speech || {}
      {
        "name" => found.member&.name.presence || speech[:speaker], "party" => found.member&.party,
        "found_by" => found.found_by.to_s, "speech" => speech[:id], "speech_date" => speech[:date]&.to_s,
        "speech_time" => ClockTime.normalise(speech[:time]).presence,
        "other_heading" => speech[:other_heading].present?
      }
    end

    def circulation
      circulation = packet.circulation
      circulation && { "by" => circulation.by, "member" => circulation.member&.name, "plural" => circulation.plural }
    end

    # How many speeches the packet holds: those beside the division, and those added from earlier in
    # the debate. A change in either is a change in what the model would read.
    def speeches
      earlier, beside = transcript.speeches.partition(&:earlier)
      { "beside" => beside.size, "earlier" => earlier.size }
    end

    def limitation
      statement = packet.limitation_statement
      return nil unless statement

      {
        "kind" => statement[:kind].to_s, "text" => statement[:text],
        "time" => ClockTime.normalise(statement[:time]).presence, "speech" => statement[:id],
        "speaker" => statement[:speaker]
      }
    end

    # Hansard's own text for some units, a blank line between runs, or nil when there are none.
    def text_of(units)
      transcript.passages(units.map(&:id)).map(&:text).join("\n\n").presence
    end

    def shorten(value)
      case value
      when Hash then value.transform_values { |item| shorten(item) }
      when Array then value.map { |item| shorten(item) }
      when String then self.class.shorten_text(value)
      else value
      end
    end
  end
end

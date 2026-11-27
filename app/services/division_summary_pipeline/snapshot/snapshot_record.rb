# frozen_string_literal: true

require "digest"

module DivisionSummaryPipeline
  # Builds one division's entry in the routing snapshot. The task is in lib/tasks/route_snapshot.rake,
  # the file it writes is made by route_snapshot.rb, and spec/route_snapshots/README.md explains
  # every field.
  #
  # Stage 1 gathers everything it finds about a division into one bundle of information (the
  # "packet", in context/context_packet.rb). This turns that bundle into a plain list of fields: what
  # Stage 2 decided, and everything Stage 1 found by its rules. route_snapshot.rb adds two fields of
  # its own straight after the facts: whether the day's Hansard was final or a proof, and which sitting
  # days were read.
  #
  # The same code and the same Hansard always give exactly the same entry, so any difference between
  # two runs shows up as a changed line. To make sure of that, the fields are always in the same
  # order, no database id numbers appear (they differ between copies of the database), and long text
  # is shortened the same way every time.
  #
  # The facts are what the database records about the vote, worked out from the votes loaded from
  # Hansard: the counts, the result and the bills. Figures the site works out later, such as
  # rebellions, are left out, so a change to them is never mistaken for a change in what Stages 1 and 2
  # decided.
  class SnapshotRecord
    # Text longer than 40 words is shortened to its first 20 words, its word count, its last 20 words
    # and a hash: a short code worked out from the whole text, so that a change anywhere in it, even
    # in the part not shown, changes the code.
    LONG_TEXT_ENDS = 20
    # How many characters of that code to show.
    HASH_LENGTH = 12

    # One division's entry, from Stage 1's packet and the extra fields route_snapshot.rb adds.
    def self.build(packet, sources = {})
      new(packet, sources).to_h
    end

    # The entry's name, for example senate_2026-09-17_1: the house, the date and the division's number
    # that day. These are the same in every copy of the database, unlike the database's own id numbers.
    def self.key(division)
      "#{division.house}_#{division.date}_#{division.number}"
    end

    # Shortens long text as described above. Text of 40 words or fewer is kept in full.
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

    # All of the entry's fields, always in this order, with every long piece of text shortened.
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

    # What the database records about the vote itself, worked out from the votes loaded from Hansard:
    # the house, date, division number and time, the result, whether it was tied, how many voted aye
    # and no (tellers included), and the bills it was about, in alphabetical order because the database
    # gives them back in no fixed order.
    def facts
      facts = packet.facts
      {
        "house" => facts.house, "date" => facts.date, "number" => facts.number,
        "time" => ClockTime.normalise(facts.clock_time).presence, "result" => facts.result, "tied" => facts.tied,
        "ayes" => facts.aye_votes, "noes" => facts.no_votes, "bills" => facts.bill_titles.sort
      }
    end

    # Stage 2's decision. The mode is "deterministic" when a rule settled the template, "constrained"
    # when a rule narrowed it to a shortlist (allowed) for the AI to choose from, and "advisory" when no
    # rule was sure, so the template is only a default the AI may change. forbidden lists templates
    # ruled out, rule names the rule that matched, and reason says why.
    def route
      routing = packet.routing
      {
        "mode" => routing.mode.to_s, "template" => routing.template_id, "allowed" => routing.allowed_templates,
        "forbidden" => routing.forbidden_templates, "rule" => routing.rule_name.to_s, "reason" => routing.reason
      }
    end

    # The question the division decided: the sentence Stage 2 based its decision on, the chair's full
    # statement putting the question, who put it and when, the parts left out of this vote when a
    # complicated question was split up (divided), and two yes or no flags: whether the question only
    # points to a motion moved earlier (by_reference), and whether it spells out the whole motion
    # itself (states_motion).
    def question
      speech = transcript.question_speech
      {
        "routed_on" => packet.speaker_question, "chair_statement" => text_of(transcript.question_units),
        "put_by" => speech&.speaker, "time" => ClockTime.normalise(speech&.time).presence,
        "divided" => ChairStatement.divided_parts(packet.speaker_question),
        "by_reference" => packet.question_by_reference?, "states_motion" => packet.question_states_motion?
      }
    end

    # The words of the motion the division decided, as Stage 1 found them: either in the speech of the
    # member who moved it, or printed in the chair's statement. The second happens when amendments
    # handed out in writing beforehand are put to the vote without anyone moving them in the chamber.
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

    # Where the motion's words were found, for the entry's found_in field.
    def motion_found_in(moved, printed)
      if moved.any? then "mover_speech"
      elsif printed.any? then "chair_statement"
      end
    end

    # Who moved the motion and their party (from the database's member records when Stage 1 matched a
    # member, otherwise the name as Hansard gives it), how Stage 1 worked out who it was (found_by),
    # and the speech it was moved in: its Hansard id, date and time, and whether it sat under a
    # different Hansard heading from the vote.
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

    # Amendments handed out in writing (circulated) and put to the vote without being moved in the
    # chamber, and who circulated them.
    def circulation
      circulation = packet.circulation
      circulation && { "by" => circulation.by, "member" => circulation.member&.name, "plural" => circulation.plural }
    end

    # How many speeches Stage 1 collected: those just before the division, and those it added from
    # earlier in the debate. A change in either number is a change in what the AI would read.
    def speeches
      earlier, beside = transcript.speeches.partition(&:earlier)
      { "beside" => beside.size, "earlier" => earlier.size }
    end

    # When debate was cut off by a time limit (a "guillotine"): the chair's statement that the time had
    # run out, and when and by whom it was made.
    def limitation
      statement = packet.limitation_statement
      return nil unless statement

      {
        "kind" => statement[:kind].to_s, "text" => statement[:text],
        "time" => ClockTime.normalise(statement[:time]).presence, "speech" => statement[:id],
        "speaker" => statement[:speaker]
      }
    end

    # Hansard's own words for the given parts of a speech, with a blank line between separate passages,
    # or nothing if there are none.
    def text_of(units)
      transcript.passages(units.map(&:id)).map(&:text).join("\n\n").presence
    end

    # Shortens every piece of text in the entry, however deep inside other fields it sits.
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

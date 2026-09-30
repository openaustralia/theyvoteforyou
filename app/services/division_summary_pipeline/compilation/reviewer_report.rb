# frozen_string_literal: true

module DivisionSummaryPipeline
  # The "Reviewer Only" section at the foot of every draft: a fixed form recording how the
  # pipeline arrived at the summary, so a reviewer can check each decision against Hansard and
  # the division record and see where an extraction or rendering went wrong.
  #
  # Every row comes from the pipeline's own structured records (the packet, the routing
  # decision, the model's interpretation and references, the evidence, the validation result
  # and the compiler's fallbacks). The only prose is the fixed wording of the form itself. It is
  # never a second, model-written account of the division, and nothing in it is the model's
  # words: the model's reply is kept, untouched, on the saved draft's raw_response.
  class ReviewerReport
    FALLBACKS = {
      mover_unresolved: "No mover was identified, so the summary names nobody as the mover.",
      no_bill_record: "The division has no bill record, so the summary says \"the bill\" without a link.",
      no_digest: "No Bills Digest was supplied, so \"No Bill Digest found.\" is printed.",
      no_explanation: "No explanatory sentences were quoted, so \"No explanatory claims recorded.\" is printed.",
      no_introduction: "The mover's \"I move\" words were not found, so none are quoted.",
      no_motion_terms: "No terms moved were found; the question put stands in for the motion.",
      no_question: "The chair's statement putting the question was not recorded, so none is quoted.",
      tied: "The votes were equal; the tied-vote notice is printed.",
      want_of_quorum: "Fewer than a quorum voted; the quorum notice is printed.",
      absolute_majority_in_doubt: "The ayes fell short of an absolute majority; the absolute majority notice is printed."
    }.freeze

    MOVER_FOUND_BY = {
      chair_named: "the chair named the mover, and their move is in the transcript",
      chair_named_only: "the chair named the mover, but their move is not in the transcript",
      recent_move: "the latest \"I move\" just before the question",
      notice_owner: "whose notice it was (\"in the name of\"), a weaker sign"
    }.freeze

    # model_id: the Bedrock model asked. extraction and validation are nil when the reply could
    # not be read; fallbacks come from TemplateCompiler#fallbacks, empty when nothing compiled.
    # widening_failure: why the retry over the whole sitting day gave nothing to use, when it was
    # tried and failed, so a reviewer knows the draft rests on the narrower packet.
    def self.render(model_id:, packet:, title:, extraction: nil, validation: nil, fallbacks: [], widening_failure: nil)
      new(model_id:, packet:, title:, extraction:, validation:, fallbacks:, widening_failure:).render
    end

    def initialize(model_id:, packet:, title:, extraction:, validation:, fallbacks:, widening_failure:)
      @model_id = model_id
      @packet = packet
      @title = title
      @extraction = extraction
      @validation = validation
      @fallbacks = fallbacks
      @widening_failure = widening_failure
    end

    def render
      [
        "---",
        "## Reviewer Only",
        "*Recorded by the pipeline from its own data, for checking this draft against Hansard. Remove this " \
        "section before publishing.*",
        section("Source", source_rows),
        section("Routing", routing_rows),
        section("Model decisions", decision_rows),
        evidence_section,
        section("Mover", mover_rows),
        list_section("Fallbacks used", fallbacks.map { |name| "`#{name}`: #{FALLBACKS.fetch(name)}" }),
        list_section("Validation errors", validation&.errors || []),
        list_section("Validation warnings", validation&.warnings || [])
      ].join("\n\n")
    end

    private

    attr_reader :model_id, :packet, :title, :extraction, :validation, :fallbacks, :widening_failure

    delegate :facts, :transcript, to: :packet

    def source_rows
      rows = [
        ["Model", "`#{model_id}`"],
        ["Division", "#{facts.chamber}, #{facts.date}, division #{facts.number}, #{facts.time}"],
        ["Hansard", packet.source == :hansard_xml ? "ParlParse division `#{packet.division_xml_id}`" : "No matching XML; built from the Division record"],
        ["Context level", packet.context_level.to_s],
        ["Earlier debate added", packet.earlier_debate_dates.presence&.join(", ") || "none"],
        ["Limitation of debate", limitation_note],
        ["Question routed on", packet.speaker_question.to_s],
        ["Question divided", divided_note],
        ["Title", "#{title} (from the heading \"#{TextNormaliser.clean_text(packet.heading)}\" and the template)"]
      ]
      return rows unless widening_failure

      rows.insert(4, ["Sitting day retry", "failed (#{widening_failure}), so this draft uses the first reply"])
    end

    def routing_rows
      routing = packet.routing
      return [%w[Decision none]] unless routing

      [
        ["Mode", routing.mode.to_s],
        ["Rule", "`#{routing.rule_name}`"],
        ["Settled template", routing.template_id || "none"],
        ["Allowed", list(routing.allowed_templates)],
        ["Forbidden", list(routing.forbidden_templates)],
        ["Reason", routing.reason]
      ]
    end

    def decision_rows
      return [["Reply", "could not be read"]] unless extraction

      [
        ["Template chosen", extraction.template_id],
        ["Declines second reading", extraction.declines_second_reading.nil? ? "not given" : extraction.declines_second_reading],
        ["Evidence reported missing", list(extraction.missing)],
        ["Explanation references", list(extraction.references.explanation)],
        ["Motion references", list(extraction.references.motion)],
        ["Fact references", list(extraction.references.facts.map { |name, ref| "#{name}: #{ref.unit}" })]
      ]
    end

    def evidence_section
      evidence = validation&.evidence
      return section("Evidence quoted", [%w[Evidence none]]) unless evidence

      rows = [["Motion introduction", evidence.introduction], ["Motion text", evidence.motion],
              ["Question put", evidence.question]]
      rows << ["Limitation of debate", evidence.limitation] if evidence.limitation
      evidence.explanations.each_with_index { |excerpt, index| rows << ["Explanation #{index + 1}", excerpt] }
      evidence.facts.each { |name, excerpt| rows << ["Fact `#{name}`", excerpt] }

      header = "| Part | Units | Speaker | Time | Found by | Text |\n|---|---|---|---|---|---|"
      lines = rows.map do |part, excerpt|
        next "| #{part} | none | | | | |" unless excerpt

        cells = [part, unit_range(excerpt.unit_ids), excerpt.speaker.presence || "the chair",
                 [excerpt.date, excerpt.time].compact_blank.join(" "), excerpt.found_by, text_note(excerpt.text)]
        "| #{cells.map { |cell| cell(cell) }.join(' | ')} |"
      end
      "### Evidence quoted\n\n#{header}\n#{lines.join("\n")}"
    end

    def mover_rows
      mover = packet.mover
      return [["Found", "no mover was identified by rule"]] unless mover

      member = mover.member
      [
        ["Found by", MOVER_FOUND_BY.fetch(mover.found_by, mover.found_by.to_s)],
        ["Speech", mover.speech ? "#{mover.speech[:speaker]} at #{mover.speech[:time]} (`#{mover.speech[:id]}`)" : "not in the transcript"],
        ["TVFY member", member&.member ? "#{member.name} (#{member.party})" : "not matched to a TVFY member"]
      ]
    end

    def divided_note
      parts = ChairStatement.divided_parts(packet.speaker_question)
      parts ? "yes: without \"#{parts}\"" : "no"
    end

    # Where the chair said the time had expired, so a reviewer can find it: it is often many
    # divisions back, under another bill's heading.
    def limitation_note
      statement = packet.limitation_statement
      return "none found" unless statement

      "the chair said the time allotted had expired, at #{ClockTime.display(statement[:time])} " \
        "(`#{statement[:id]}`)"
    end

    # The first words, so a reviewer can find the passage; the full text is in the summary above.
    def text_note(text)
      words = text.to_s.split
      preview = words.first(12).join(" ")
      "#{preview}#{' ...' if words.size > 12} (#{text.to_s.size} characters)"
    end

    # "S1.2-S1.11" for a run of units in one speech.
    def unit_range(ids)
      return "outside the transcript" if ids.empty?
      return ids.first.to_s if ids.size < 2

      "#{ids.first}-#{ids.last}"
    end

    def section(heading, rows)
      table = rows.map { |label, value| "| #{cell(label)} | #{cell(value)} |" }.join("\n")
      "### #{heading}\n\n| | |\n|---|---|\n#{table}"
    end

    def list_section(heading, items)
      body = items.empty? ? "None." : items.map { |item| "- #{item.to_s.gsub(/\s+/, ' ')}" }.join("\n")
      "### #{heading}\n\n#{body}"
    end

    def list(values)
      values.presence&.join(", ") || "none"
    end

    def cell(value)
      value.to_s.gsub(/\s+/, " ").gsub("|", "\\|")
    end
  end
end

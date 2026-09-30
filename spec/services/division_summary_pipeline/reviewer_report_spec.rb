# frozen_string_literal: true

require "spec_helper"

describe DivisionSummaryPipeline::ReviewerReport do
  let(:question) { "The question is that the second reading amendment moved by Senator Treloar on sheet 9001 be agreed to." }
  let(:speeches) do
    [
      summary_speech(<<~XML, id: "s1", name: "Morgan Treloar", gid: "uk.org.publicwhip/lord/900001", time: "13:20"),
        <p>Rural students pay more to study.</p>
        <p>I move the second reading amendment on sheet 9001:</p>
        <p class="italic">At the end of the motion, add ", but the Senate notes the cost".</p>
      XML
      summary_speech("<p>#{question}</p>", id: "s2", name: "Robin Castellan", gid: "uk.org.publicwhip/lord/900002", time: "13:30")
    ]
  end
  let(:routing) do
    DivisionSummaryPipeline::RoutingDecision.fenced([2, 29], rule_name: "SECOND_READING_NUANCE",
                                                             reason: "Second reading question.")
  end
  let(:packet) do
    summary_packet(speeches: speeches, question: question, warnings: ["No debate speeches were found."],
                   routing: routing)
  end
  let(:extraction) do
    DivisionSummaryPipeline::ExtractionPayload.from_h(
      "interpretation" => { "template_id" => 2, "declines_second_reading" => false, "missing" => [] },
      "references" => { "explanation" => %w[S1.1 S1.3] }
    )
  end
  let(:validation) { DivisionSummaryPipeline::ProvenanceValidator.validate(extraction, packet) }

  def report(**overrides)
    described_class.render(model_id: "example.model-v1:0", packet: packet, title: "Bills - Example Bill 2026; Second Reading Amendment",
                           extraction: extraction, validation: validation, fallbacks: [:no_digest], **overrides)
  end

  it "says when the sitting day retry failed, and only then" do
    expect(report(widening_failure: "the model timed out"))
      .to include("| Sitting day retry | failed (the model timed out), so this draft uses the first reply |")
    expect(report).not_to include("Sitting day retry")
  end

  it "has the same fixed sections on every draft" do
    headings = report.scan(/^#+ .*/)

    expect(headings).to eq(["## Reviewer Only", "### Source", "### Routing", "### Model decisions", "### Evidence quoted",
                            "### Mover", "### Explanation sentences to look at twice", "### Fallbacks used",
                            "### Validation errors", "### Validation warnings"])
    expect(report).to start_with("---\n\n## Reviewer Only")
  end

  # KI-58: a barb at an opponent can pass as "a reason".
  it "flags a quoted explanation that speaks to someone or names another member, for the reviewer only" do
    pointed = [summary_speech("<p>You have let students down. The scheme costs too much.</p><p>I move:</p>" \
                              "<p class=\"italic\">At the end of the motion, add \", but the Senate notes the cost\".</p>",
                              id: "s1", name: "Morgan Treloar", gid: "uk.org.publicwhip/lord/900001", time: "13:20"), speeches.last]
    context = summary_packet(speeches: pointed, question: question, routing: routing)
    reply = DivisionSummaryPipeline::ExtractionPayload.from_h(
      "interpretation" => { "template_id" => 2, "declines_second_reading" => false, "missing" => [] },
      "references" => { "explanation" => %w[S1.1 S1.2] }
    )
    flagged = report(packet: context, validation: DivisionSummaryPipeline::ProvenanceValidator.validate(reply, context))

    expect(flagged).to include("### Explanation sentences to look at twice\n\n- S1.1-S1.2: You have let students down.")
    expect(report).to include("### Explanation sentences to look at twice\n\nNone.")
  end

  it "records each decision from the pipeline's own data" do
    expect(report).to include("| Model | `example.model-v1:0` |", "| Mode | constrained |", "| Rule | `SECOND_READING_NUANCE` |",
                              "| Allowed | 2, 29 |", "| Template chosen | 2 |", "| Declines second reading | false |",
                              "| Explanation references | S1.1, S1.3 |")
  end

  it "shows where each quote came from and how it was found" do
    expect(report).to include("| Motion introduction | S1.2 | Morgan Treloar | 13:20 | rule |",
                              "| Motion text | S1.3 | Morgan Treloar | 13:20 | rule |",
                              "| Question put | S2.1 | Robin Castellan | 13:30 | rule |",
                              "| Explanation 1 | S1.1 | Morgan Treloar | 13:20 | model | Rural students pay more to study. (33 characters) |")
  end

  # It is often many divisions back, under another bill's heading.
  it "says where the chair said a limitation of debate's time had expired, and only when they did" do
    statement = { id: "uk.org.publicwhip/lords/2026-08-20.54.2", speaker: "Robin Castellan", speaker_gid: nil, time: "13:15",
                  text: "Pursuant to order, the time allotted for this bill has expired." }
    guillotined = summary_packet(speeches: speeches, question: question, routing: routing, limitation_statement: statement)
    rendered = report(packet: guillotined, validation: DivisionSummaryPipeline::ProvenanceValidator.validate(extraction, guillotined))

    expect(rendered).to include("| Limitation of debate | the chair said the time allotted had expired, at 1:15 PM " \
                                "(`uk.org.publicwhip/lords/2026-08-20.54.2`) |",
                                "| Limitation of debate | outside the transcript | Robin Castellan | 13:15 | rule |")
    expect(report).to include("| Limitation of debate | none found |")
  end

  it "lists the fallbacks, the warnings and how the mover was found" do
    expect(report).to include("`no_digest`: No Bills Digest was supplied", "S1.3 is motion text",
                              "Context warning: No debate speeches were found.",
                              "| Found by | the chair named the mover, and their move is in the transcript |")
    expect(report).to include("### Validation errors\n\nNone.")
  end

  it "still has every section when the reply could not be read" do
    failed = report(extraction: nil, validation: nil, fallbacks: [])

    expect(failed).to include("| Reply | could not be read |", "### Evidence quoted", "### Validation errors\n\nNone.")
  end

  # The report records decisions; it is never a second account of the division in the model's words.
  it "contains nothing the model wrote" do
    raw = { "interpretation" => { "template_id" => 2, "declines_second_reading" => false, "missing" => [],
                                  "topic" => "A MODEL-WRITTEN TOPIC" }, "references" => { "explanation" => [] } }
    extraction = DivisionSummaryPipeline::ExtractionPayload.from_h(raw)

    expect(report(extraction: extraction)).not_to include("MODEL-WRITTEN")
  end

  it "escapes table cells so Hansard text cannot break the table" do
    packet_with_pipe = packet.with(speaker_question: "The question is that clause 1 | 2 stand.")

    expect(report(packet: packet_with_pipe)).to include("clause 1 \\| 2 stand.")
  end
end

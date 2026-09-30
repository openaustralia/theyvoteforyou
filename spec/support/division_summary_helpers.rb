# frozen_string_literal: true

# Builders for the AI division summary pipeline's specs, so each spec can state the evidence a
# stage receives in plain strings rather than building a transcript for every example. The
# names and words used with these are fictional, per AGENTS.md.
module DivisionSummaryHelpers
  def summary_excerpt(text, speaker: "Morgan Treloar", time: "13:27", date: nil, found_by: :rule, unit_ids: ["S1.1"])
    return nil if text.nil?

    DivisionSummaryPipeline::Evidence::Excerpt.new(text: text, unit_ids: unit_ids, speaker: speaker, speaker_gid: nil,
                                                   time: time, date: date, found_by: found_by)
  end

  # The interpretation and evidence Stage 5 compiles from. explanations are the mover's own
  # sentences; facts maps a fact name to the text Hansard gives for it.
  def summary_inputs(template_id:, motion_text: nil, question_text: nil, introduction: nil, declines_second_reading: nil,
                     explanations: [], facts: {}, mover: nil, limitation: nil, circulation: nil)
    interpretation = DivisionSummaryPipeline::ExtractionPayload::Interpretation.new(
      template_id: template_id, declines_second_reading: declines_second_reading, missing: []
    )
    evidence = DivisionSummaryPipeline::Evidence.new(
      introduction: summary_excerpt(introduction),
      motion: summary_excerpt(motion_text),
      question: summary_excerpt(question_text, speaker: "Robin Castellan", time: "13:30"),
      explanations: explanations.map { |text| summary_excerpt(text, found_by: :model) },
      facts: facts.to_h { |name, text| [name.to_sym, summary_excerpt(text, found_by: :model)] },
      mover: mover,
      limitation: summary_excerpt(limitation, speaker: "Robin Castellan", time: "13:15", unit_ids: []),
      circulation: circulation
    )
    [interpretation, evidence]
  end

  # One <speech> in the shape current ParlParse XML has, read the way Stage 1 reads it.
  def summary_speech(inner_xml, id:, name:, gid:, time:)
    node = Nokogiri::XML("<speech id=\"#{id}\" speakername=\"#{name}\" speakerid=\"#{gid}\" time=\"#{time}\">" \
                         "#{inner_xml}</speech>").root
    DataLoader::SpeechText.context_speech(node)
  end

  # A Stage 1 packet over the given speeches, the last of which is the chair putting the
  # question, with the mover found by the same rule Stage 1 uses.
  def summary_packet(speeches:, question:, routing:, warnings: [], heading: "Bills &#8212; Example Bill 2026; Second Reading",
                     facts: { house: "senate", date: "2026-09-17", number: 4, clock_time: "13:31" }, limitation_statement: nil,
                     circulation: nil)
    transcript = DivisionSummaryPipeline::Transcript.build(heading: heading, speeches: speeches,
                                                           question_speech_id: speeches.last[:id])
    DivisionSummaryPipeline::ContextPacket.new(
      facts: DivisionSummaryPipeline::DivisionFacts.from(facts), heading: heading, speaker_question: question,
      transcript: transcript, mover: DivisionSummaryPipeline::MoverFinder.find(question: question, speeches: speeches),
      routing: routing, context_level: :subdebate, context_warnings: warnings, source: :hansard_xml, division_xml_id: "d9",
      limitation_statement: limitation_statement, circulation: circulation
    )
  end

  def compile_summary(division_data, digest_section: nil, **inputs)
    DivisionSummaryPipeline::TemplateCompiler.compile(division_data, *summary_inputs(**inputs), digest_section: digest_section)
  end
end

RSpec.configure do |config|
  config.include DivisionSummaryHelpers
end

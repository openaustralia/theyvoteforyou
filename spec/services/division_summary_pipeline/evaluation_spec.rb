# frozen_string_literal: true

require "spec_helper"
require "json"

describe "Parliamentary Evaluation Corpus" do
  # Fictional fixtures (see ARCHITECTURE.md in the pipeline directory's "fictional data" note) exercising
  # the pipeline end to end against real ParlParse <debates> XML - the shape ContextBuilder
  # actually parses in production (see DivisionSummaryPipeline::ContextBuilder).
  let(:fixtures_root) { File.expand_path("../../fixtures/division_summaries", __dir__) }

  describe "Fixture 1: Template 2 - Second Reading Amendment" do
    let(:fixture_dir) { File.join(fixtures_root, "test_1") }
    let(:division_data) { JSON.parse(File.read(File.join(fixture_dir, "division.json"))) }
    let(:expected_extraction) { JSON.parse(File.read(File.join(fixture_dir, "expected_extraction.json"))) }
    let(:expected_output) { File.read(File.join(fixture_dir, "expected_output.md")).strip }
    let(:hansard_xml) do
      xml_file = File.join(fixture_dir, "hansard_excerpt.xml")
      File.exist?(xml_file) ? File.read(xml_file) : nil
    end

    it "routes and compiles with 100% provenance and exact expected output" do
      # 1. Context Builder
      packet = DivisionSummaryPipeline::ContextBuilder.build(
        division_data,
        xml_content: hansard_xml
      )
      expect(packet.speaker_question).to include("amendment moved by the honourable member for Fairview be agreed to")

      # 2. Procedural Router
      decision = packet.procedural_decision
      expect(decision.candidate_templates).to include(2)
      expect(decision.locked_out_templates).not_to include(2)

      # 3. Extraction Payload
      extraction = DivisionSummaryPipeline::ExtractionPayload.from_h(expected_extraction)
      expect(extraction.template_id).to eq(2)
      expect(extraction.declines_second_reading).to be(true)

      # 4. Provenance Validator
      validation = DivisionSummaryPipeline::ProvenanceValidator.validate(extraction, packet)
      expect(validation.is_valid).to be(true)
      expect(validation.errors).to be_empty

      # 5. Template Compiler
      compiled = DivisionSummaryPipeline::TemplateCompiler.compile(division_data, extraction)
      expect(compiled.strip).to eq(expected_output)
    end
  end

  describe "Fixture 2: Template 22 - Closure of Debate" do
    let(:fixture_dir) { File.join(fixtures_root, "test_2") }
    let(:division_data) { JSON.parse(File.read(File.join(fixture_dir, "division.json"))) }
    let(:expected_extraction) { JSON.parse(File.read(File.join(fixture_dir, "expected_extraction.json"))) }
    let(:expected_output) { File.read(File.join(fixture_dir, "expected_output.md")).strip }
    let(:hansard_xml) do
      xml_file = File.join(fixture_dir, "hansard_excerpt.xml")
      File.exist?(xml_file) ? File.read(xml_file) : nil
    end

    it "routes and compiles with 100% provenance and exact expected output" do
      # 1. Context Builder
      packet = DivisionSummaryPipeline::ContextBuilder.build(
        division_data,
        xml_content: hansard_xml
      )
      expect(packet.speaker_question).to include("question be now put")

      # 2. Procedural Router
      decision = packet.procedural_decision
      expect(decision.is_deterministic).to be(true)
      expect(decision.template_id).to eq(22)

      # 3. Extraction Payload
      extraction = DivisionSummaryPipeline::ExtractionPayload.from_h(expected_extraction)
      expect(extraction.template_id).to eq(22)

      # 4. Provenance Validator
      validation = DivisionSummaryPipeline::ProvenanceValidator.validate(extraction, packet)
      expect(validation.is_valid).to be(true)
      expect(validation.errors).to be_empty

      # 5. Template Compiler
      compiled = DivisionSummaryPipeline::TemplateCompiler.compile(division_data, extraction)
      expect(compiled.strip).to eq(expected_output)
    end
  end
end


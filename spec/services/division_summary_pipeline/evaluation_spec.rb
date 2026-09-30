# frozen_string_literal: true

require "spec_helper"
require "json"

# rubocop:disable RSpec/DescribeClass -- exercises the whole pipeline end to end, not one class
describe "Parliamentary Evaluation Corpus" do
  # Fictional fixtures (see ARCHITECTURE.md in the pipeline directory's "fictional data" note)
  # driving stages 1, 2, 4 and 5 against ParlParse <debates> XML, with the model's reply read from
  # the fixture rather than asked for, so nothing leaves the machine.
  let(:fixtures_root) { File.expand_path("../../fixtures/division_summaries", __dir__) }

  def fixture(name, file)
    File.read(File.join(fixtures_root, name, file))
  end

  def run_fixture(name)
    division_data = JSON.parse(fixture(name, "division.json"))
    packet = DivisionSummaryPipeline::ContextBuilder.build(division_data, xml_content: fixture(name, "hansard_excerpt.xml"))
    extraction = DivisionSummaryPipeline::ExtractionPayload.from_json(fixture(name, "expected_extraction.json"))
    validation = DivisionSummaryPipeline::ProvenanceValidator.validate(extraction, packet)
    compiled = DivisionSummaryPipeline::TemplateCompiler.compile(division_data, extraction.interpretation, validation.evidence)
    { packet: packet, validation: validation, compiled: compiled }
  end

  describe "Fixture 1: Template 2 - Second Reading Amendment moved formally" do
    # The chair names the mover only by electorate, which takes the member's record to match.
    before do
      create(:member, person: create(:person), gid: "au.org.tvfy/member/10", first_name: "Priya", last_name: "Nakamura",
                      constituency: "Fairview", party: "Independent", house: "representatives",
                      entered_house: "2020-01-01", left_house: "9999-12-31")
    end

    it "routes, finds the motion by rule, and compiles exactly the expected output" do
      result = run_fixture("test_1")

      expect(result[:packet].routing.allowed_templates).to include(2)
      expect(result[:packet]).to be_motion_found
      expect(result[:validation]).to be_valid
      expect(result[:compiled]).to eq(fixture("test_1", "expected_output.md").strip)
    end

    # The mover said nothing beyond "I move:" and the amendment, so there is nothing to
    # quote as an explanation, and the amendment's own clauses must not stand in for one.
    it "says no explanation was recorded rather than restating the amendment" do
      expect(run_fixture("test_1")[:compiled]).to include("### About the Amendment\n\n> No explanatory claims recorded.")
    end
  end

  describe "Fixture 2: Template 22 - Closure of Debate" do
    it "routes, finds the motion by rule, and compiles exactly the expected output" do
      result = run_fixture("test_2")

      expect(result[:packet].routing).to be_deterministic
      expect(result[:packet].routing.template_id).to eq(22)
      expect(result[:validation]).to be_valid
      expect(result[:compiled]).to eq(fixture("test_2", "expected_output.md").strip)
    end
  end
end
# rubocop:enable RSpec/DescribeClass

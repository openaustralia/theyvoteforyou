# frozen_string_literal: true

require "spec_helper"

# The catalogue and the template files describe the same templates from two sides, and
# nothing else stops them drifting apart: TemplateCompiler renders an unknown placeholder as
# empty rather than failing, so a mismatch shows up only as a quietly missing section.
describe DivisionSummaryPipeline::TemplateCatalogue do
  let(:templates_dir) { DivisionSummaryPipeline::TemplateCompiler::DEFAULT_TEMPLATES_DIR }

  def template_files(id)
    Dir.glob(File.join(templates_dir, "#{id}_*.md"))
  end

  def template_text(id)
    File.read(template_files(id).first, encoding: "utf-8")
  end

  def placeholder?(text, name)
    text.match?(/\{\{\s*#{Regexp.escape(name)}\s*\}\}/)
  end

  it "has an entry for each of the ids 1 to 29 and no others" do
    expect(described_class::ENTRIES.keys).to eq((1..29).to_a)
    expect(described_class::IDS).to eq(1..29)
  end

  it "has exactly one template file for each id" do
    described_class::IDS.each do |id|
      expect(template_files(id).size).to eq(1), "expected one template file for Template #{id}, found #{template_files(id).inspect}"
    end
  end

  it "has no template file for an id it does not know" do
    ids = Dir.glob(File.join(templates_dir, "*.md")).map { |path| File.basename(path)[/\A\d+/].to_i }

    expect(ids.sort).to eq(described_class::IDS.to_a)
  end

  it "explains exactly the templates that quote the mover's explanation" do
    described_class.entries.each do |entry|
      quotes_explanation = placeholder?(template_text(entry.id), "explanation_section")

      expect(quotes_explanation).to eq(entry.explains), "Template #{entry.id}: explains is #{entry.explains}"
    end
  end

  it "requires only facts the entry names" do
    described_class.entries.each do |entry|
      expect(entry.requires.flatten - entry.facts.keys).to be_empty, "Template #{entry.id} requires an unnamed fact"
    end
  end

  it "prints the motion and the question put in every template" do
    described_class.entries.each do |entry|
      text = template_text(entry.id)

      %w[question_put motion_introduction motion_attribution motion_text].each do |name|
        expect(placeholder?(text, name)).to be(true), "Template #{entry.id} is missing {{#{name}}}"
      end
    end
  end

  it "has no template that still prints a model-written topic or claims" do
    described_class.entries.each do |entry|
      text = template_text(entry.id)

      %w[topic introducer_claims].each do |name|
        expect(placeholder?(text, name)).to be(false), "Template #{entry.id} still uses {{#{name}}}"
      end
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

describe DivisionSummaryIngest do
  let(:user) { create(:confirmed_user, admin: true) }
  let!(:division) { create(:division, house: "representatives", date: Date.new(2026, 9, 17), number: 3) }
  let(:model) { "local.Example-Model-Q4" }
  let(:path) { "#{model}/representatives/2026-09-17/representatives_2026-09-17_3.md" }
  let(:draft) { "# Bills - Example Bill 2026; First Reading\n\nThe House voted on the Example Bill.\n" }

  def ingest_for(files)
    ingest = Ingest.create!(kind: "division-summary", user: user, file_path: build_zip(files).to_s)
    described_class.new(ingest).process
  end

  it "saves the draft against the division, credited to the model, with line 1 as its title" do
    result = ingest_for(path => draft)

    summary = division.ai_division_summaries.sole
    expect(result.errors).to be_empty
    expect(summary).to have_attributes(model: model, title: "Bills - Example Bill 2026; First Reading",
                                       description: "The House voted on the Example Bill.")
  end

  it "links the draft back to the upload it arrived in" do
    ingest = Ingest.create!(kind: "division-summary", user: user, file_path: build_zip(path => draft).to_s)
    described_class.new(ingest).process
    expect(division.ai_division_summaries.sole.ingest).to eq(ingest)
  end

  it "reads the division from the file name, not the folders" do
    result = ingest_for("#{model}/anything/at-all/representatives_2026-09-17_3.md" => draft)
    expect(result.saved).to eq(1)
  end

  it "replaces an earlier draft from the same model" do
    ingest_for(path => draft)
    ingest_for(path => "# A newer title\n\nA newer description.")
    expect(division.ai_division_summaries.sole.title).to eq("A newer title")
  end

  it "keeps drafts from different models side by side" do
    ingest_for(path => draft, "other.model/representatives/2026-09-17/representatives_2026-09-17_3.md" => draft)
    expect(division.ai_division_summaries.pluck(:model)).to contain_exactly(model, "other.model")
  end

  it "leaves a draft the pipeline made itself alone when it is for a different model" do
    AiDivisionSummary.create!(division: division, model: "bedrock.model", title: "Mine", description: "Mine")
    ingest_for(path => draft)
    expect(division.ai_division_summaries.pluck(:model)).to contain_exactly("bedrock.model", model)
  end

  context "when any file is wrong" do
    it "fails the whole upload for a division we don't have, and saves nothing" do
      result = ingest_for(path => draft, "#{model}/senate/2026-09-17/senate_2026-09-17_99.md" => draft)

      expect(result.errors.sole).to include("senate_2026-09-17_99.md is for a division we don't have")
      expect(AiDivisionSummary.count).to eq(0)
    end

    it "reports every problem, not just the first" do
      result = ingest_for("#{model}/notes.md" => draft, "#{model}/senate_2026-09-17_99.md" => draft)
      expect(result.errors.size).to eq(2)
    end

    it "rejects a file with no title line" do
      result = ingest_for(path => "\n")
      expect(result.errors.sole).to include("has no title")
    end

    it "rejects a file with a title but no description" do
      result = ingest_for(path => "# Only a title")
      expect(result.errors.sole).to include("has no description")
    end

    it "rejects two files for the same model and division" do
      result = ingest_for(path => draft, "#{model}/other/representatives_2026-09-17_3.md" => draft)
      expect(result.errors.sole).to include("more than one draft")
    end

    it "rejects a file that is not inside a model folder" do
      result = ingest_for("representatives_2026-09-17_3.md" => draft)
      expect(result.errors.sole).to include("not inside a model folder")
    end

    it "rejects a model folder name that could be a path trick" do
      result = ingest_for("..bad name/representatives_2026-09-17_3.md" => draft)
      expect(result.errors.sole).to include("model folder name")
    end

    it "rejects a date that is not a real date" do
      result = ingest_for("#{model}/representatives_2026-13-45_3.md" => draft)
      expect(result.errors.sole).to include("is for a division we don't have")
    end
  end

  it "ignores the files a Mac adds to a zip" do
    result = ingest_for(path => draft, "__MACOSX/#{model}/._x.md" => "junk", "#{model}/.DS_Store" => "junk")
    expect(result.errors).to be_empty
  end

  it "reports an empty zip" do
    expect(ingest_for("readme.txt" => "x").errors.sole).to include("not inside a model folder").or include("not named")
  end

  it "reports a file that is not a zip" do
    file = Rails.root.join("tmp/test_zips/not_a_zip.zip")
    FileUtils.mkdir_p(file.dirname)
    File.write(file, "this is not a zip")
    ingest = Ingest.create!(kind: "division-summary", user: user, file_path: file.to_s)

    expect(described_class.new(ingest).process.errors.sole).to start_with("Could not read the zip")
  end
end

# frozen_string_literal: true

require "spec_helper"

describe LocalDraftFile do
  let(:root) { Rails.root.join("tmp/test_local_runs") }
  let(:division) { build(:division, house: "senate", date: Date.new(2026, 9, 17), number: 8, name: "Bills - Example Bill 2026") }
  let(:file) { described_class.new(division, "local.Example-Model-Q4", root: root) }

  after { FileUtils.rm_rf(root) }

  def result(title: "Bills - Example Bill 2026; Second Reading", description: "The draft.", error: nil)
    DivisionSummarizer::Result.new(model: "local.Example-Model-Q4", title: title, description: description, error: error)
  end

  it "is named after the division's URL, under the model, house and date" do
    expect(file.path).to eq root.join("local.Example-Model-Q4/senate/2026-09-17/senate_2026-09-17_8.md")
  end

  it "keeps failed drafts outside the model's folder" do
    expect(file.failed_path).to eq root.join("failed/local.Example-Model-Q4/senate_2026-09-17_8.md")
  end

  describe "#write" do
    it "puts the title on line 1 as a heading and the description after it" do
      file.write(result)

      expect(File.read(file.path)).to eq "# Bills - Example Bill 2026; Second Reading\n\nThe draft.\n"
      expect(file).to be_drafted
    end

    it "removes a failed draft left from an earlier try" do
      file.write_failed(result(error: "Validation failed: no motion"))
      file.write(result)

      expect(file).not_to be_failed
    end

    it "leaves nothing half-written beside the draft" do
      file.write(result)

      expect(Dir.children(file.path.dirname)).to eq ["senate_2026-09-17_8.md"]
    end

    it "names its half-written file with a leading dot, so the upload ignores it" do
      FileUtils.mkdir_p(file.path.dirname)
      Dir.mkdir(file.path)

      expect { file.write(result) }.to raise_error(Errno::EISDIR)
      expect(Dir.children(file.path.dirname)).to include ".senate_2026-09-17_8.md.partial"
    end
  end

  describe "#write_failed" do
    it "puts the error first, ahead of whatever the pipeline produced" do
      file.write_failed(result(error: "Validation failed: no motion", description: "## Reviewer Only"))

      expect(File.read(file.failed_path))
        .to eq "# Bills - Example Bill 2026; Second Reading\n\n**Error:** Validation failed: no motion\n\n## Reviewer Only\n"
      expect(file).not_to be_drafted
    end

    it "uses the division's own name when the draft failed before it had a title" do
      file.write_failed(result(title: nil, description: nil, error: "Pipeline error: boom"))

      expect(File.read(file.failed_path)).to start_with "# Bills - Example Bill 2026\n\n**Error:** Pipeline error: boom"
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

describe ProcessIngestJob do
  let(:ingest) { Ingest.create!(kind: "division-summary", original_filename: "drafts.zip", file_path: "unused.zip") }

  after { FileUtils.rm_rf(Rails.configuration.x.ingest_root) }

  it "has a processor for every kind of ingest" do
    expect(described_class::PROCESSORS.keys).to match_array(Ingest::KINDS)
  end

  context "when the job runs again after the upload is done and its zip is gone" do
    let(:ingest) do
      Ingest.create!(kind: "division-summary", original_filename: "drafts.zip", status: "done", records_saved: 3)
    end

    it "leaves the upload as it was" do
      allow(DivisionSummaryIngest).to receive(:new)
      described_class.perform_now(ingest)

      expect(DivisionSummaryIngest).not_to have_received(:new)
      expect(ingest.reload).to have_attributes(status: "done", records_saved: 3, error: nil)
    end
  end

  context "when the drafts are saved but the zip can't be removed" do
    before do
      processor = instance_double(DivisionSummaryIngest, process: DivisionSummaryIngest::Result.new(saved: 2, errors: []))
      allow(DivisionSummaryIngest).to receive(:new).and_return(processor)
      allow(ingest).to receive(:discard_upload!).and_raise(Errno::EACCES)
    end

    it "keeps the upload done, and lets the error reach the queue's retry" do
      expect { described_class.perform_now(ingest) }.to raise_error(Errno::EACCES)

      expect(ingest.reload).to have_attributes(status: "done", records_saved: 2, error: nil)
    end

    it "does not read the zip again on the retry, and removes it" do
      ingest.store!(Rack::Test::UploadedFile.new(build_zip("a/b.md" => "x"), "application/zip"))
      zip = ingest.file_path
      expect { described_class.perform_now(ingest) }.to raise_error(Errno::EACCES)
      allow(ingest).to receive(:discard_upload!).and_call_original
      described_class.perform_now(ingest)

      expect(DivisionSummaryIngest).to have_received(:new).once
      expect(File).not_to exist(zip)
      expect(ingest.reload.file_path).to be_nil
    end
  end

  context "when the upload has more problems than the error column can hold" do
    let(:errors) { Array.new(2_000) { |n| "model/senate_2026-09-17_#{n}.md is not a file we can read #{'x' * 100}" } }

    before do
      processor = instance_double(DivisionSummaryIngest, process: DivisionSummaryIngest::Result.new(saved: 0, errors: errors))
      allow(DivisionSummaryIngest).to receive(:new).and_return(processor)
    end

    it "lists the first few and says how many more there were" do
      described_class.perform_now(ingest)

      expect(ingest.reload).to have_attributes(status: "failed", error: include(errors.first, "and 1950 more"))
      expect(ingest.error).not_to include(errors.last)
    end
  end

  context "when the processor raises something unexpected" do
    let(:bug) { RuntimeError.new("something we didn't expect") }

    before { allow(DivisionSummaryIngest).to receive(:new).and_raise(bug) }

    it "records the error on the upload for the admin page" do
      described_class.perform_now(ingest)
      expect(ingest.reload).to have_attributes(status: "failed", error: "RuntimeError: something we didn't expect")
    end

    it "keeps the uploaded zip" do
      ingest.store!(Rack::Test::UploadedFile.new(build_zip("a/b.md" => "x"), "application/zip"))
      described_class.perform_now(ingest)
      expect(File).to exist(ingest.reload.file_path)
    end

    it "reports it to Sentry, which the admin page alone would never do" do
      allow(Sentry).to receive(:capture_exception)
      described_class.perform_now(ingest)
      expect(Sentry).to have_received(:capture_exception).with(bug)
    end
  end
end

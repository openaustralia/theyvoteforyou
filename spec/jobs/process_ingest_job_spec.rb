# frozen_string_literal: true

require "spec_helper"

describe ProcessIngestJob do
  let(:ingest) { Ingest.create!(kind: "division-summary", original_filename: "drafts.zip", file_path: "unused.zip") }

  it "has a processor for every kind of ingest" do
    expect(described_class::PROCESSORS.keys).to match_array(Ingest::KINDS)
  end

  context "when the processor raises something unexpected" do
    let(:bug) { RuntimeError.new("something we didn't expect") }

    before { allow(DivisionSummaryIngest).to receive(:new).and_raise(bug) }

    it "records the error on the upload for the admin page" do
      described_class.perform_now(ingest)
      expect(ingest.reload).to have_attributes(status: "failed", error: "RuntimeError: something we didn't expect")
    end

    it "reports it to Sentry, which the admin page alone would never do" do
      allow(Sentry).to receive(:capture_exception)
      described_class.perform_now(ingest)
      expect(Sentry).to have_received(:capture_exception).with(bug)
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

describe LogApiCallJob do
  it "does nothing if the row has been trimmed while the job waited" do
    allow(Searchkick).to receive(:client)
    described_class.perform_now(0)
    expect(Searchkick).not_to have_received(:client)
  end
end

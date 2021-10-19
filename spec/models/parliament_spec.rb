# frozen_string_literal: true

require "spec_helper"

describe Parliament, type: :model do
  describe "#latest" do
    it { expect(described_class.latest).to eq "2013" }
  end
end

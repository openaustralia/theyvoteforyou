# frozen_string_literal: true

require "spec_helper"

describe ENV do
  describe ".true?" do
    let(:key) { "ENV_TRUE_SPEC_TEST_VAR" }

    after { described_class.delete(key) }

    context "with values meaning false" do
      it "is false when unset" do
        described_class.delete(key)
        expect(described_class.true?(key)).to be false
      end

      it "is false for a blank string" do
        described_class[key] = ""
        expect(described_class.true?(key)).to be false
      end

      %w[0 false FALSE off OFF f F].each do |value|
        it "is false for #{value.inspect}" do
          described_class[key] = value
          expect(described_class.true?(key)).to be false
        end
      end
    end

    context "with values meaning true" do
      %w[1 true TRUE yes on].each do |value|
        it "is true for #{value.inspect}" do
          described_class[key] = value
          expect(described_class.true?(key)).to be true
        end
      end
    end

    context "with an unrecognised value" do
      it "fails open (treats it as true), since only known false-like strings count as false" do
        described_class[key] = "banana"
        expect(described_class.true?(key)).to be true
      end
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

describe MembersHelper, type: :helper do
  describe "#member_rebellion_record_sentence" do
    context "when the associated person has not rebelled" do
      let(:member) do
        mock_model Member, person: mock_model(Person, rebellions_fraction: 0)
      end

      context "when they are a former member" do
        before { allow(member).to receive(:currently_in_parliament?).and_return false }

        it { expect(helper.member_rebellion_record_sentence(member)).to eq "Never rebelled" }
      end

      context "when they are a current member" do
        before { allow(member).to receive(:currently_in_parliament?).and_return true }

        it { expect(helper.member_rebellion_record_sentence(member)).to eq "Never rebels" }
      end
    end

    context "when the associated person has rebelled" do
      let(:member) do
        mock_model Member, person: mock_model(Person, rebellions_fraction: 0.5)
      end

      context "when they are a former member" do
        before { allow(member).to receive(:currently_in_parliament?).and_return false }

        it { expect(helper.member_rebellion_record_sentence(member)).to eq "Rebelled 50% of the time" }
      end

      context "when they are a current member" do
        before { allow(member).to receive(:currently_in_parliament?).and_return true }

        it { expect(helper.member_rebellion_record_sentence(member)).to eq "Rebels 50% of the time" }
      end
    end
  end
end

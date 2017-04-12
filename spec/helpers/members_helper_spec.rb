require 'spec_helper'

describe MembersHelper, type: :helper do
  describe "#member_rebellion_record_sentence" do
    context "Former member who not has rebelled" do
      let(:member) do
        mock_model Member, person: mock_model(Person, rebellions_fraction: 0),
                           currently_in_parliament?: false
      end

      it { expect(helper.member_rebellion_record_sentence(member)).to eq "Never rebelled" }
    end

    context "Current member who does not rebel" do
      let(:member) do
        mock_model Member, person: mock_model(Person, rebellions_fraction: 0),
                           currently_in_parliament?: true
      end

      it { expect(helper.member_rebellion_record_sentence(member)).to eq "Never rebels" }
    end

    context "Former member who has rebelled" do
      let(:member) do
        mock_model Member, person: mock_model(Person, rebellions_fraction: 0.5),
                           currently_in_parliament?: false
      end

      it { expect(helper.member_rebellion_record_sentence(member)).to eq "Rebelled 50% of the time" }
    end

    context "Current member who rebels" do
      let(:member) do
        mock_model Member, person: mock_model(Person, rebellions_fraction: 0.5),
                           currently_in_parliament?: true
      end

      it { expect(helper.member_rebellion_record_sentence(member)).to eq "Rebels 50% of the time" }
    end
  end
end

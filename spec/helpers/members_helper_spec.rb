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

  describe "#member_type_party_place_sentence" do
    context "with a member currently in parliament" do
      let(:member) { create(:member, house: "representatives", party: "Pool", constituency: "Acme") }

      it do
        expect(helper.member_type_party_place_sentence(member)).to eq '<span class="org">Pool</span> <span class="title">Representative for <span class="electorate">Acme</span></span>'
      end
    end

    context "with a senator currently in parliament" do
      let(:member) { create(:member, house: "senate", party: "Pool", constituency: "NSW") }

      it do
        expect(helper.member_type_party_place_sentence(member)).to eq '<span class="org">Pool</span> <span class="title">Senator for <span class="electorate">NSW</span></span>'
      end
    end

    context "with a former member of parliament" do
      let(:member) { create(:member, house: "representatives", party: "Pool", constituency: "Acme", left_house: Date.new(2000, 1, 1)) }

      it do
        expect(helper.member_type_party_place_sentence(member)).to eq 'Former <span class="org">Pool</span> <span class="title">Representative for <span class="electorate">Acme</span></span>'
      end
    end

    context "with a former senator" do
      let(:member) { create(:member, house: "senate", party: "Pool", constituency: "NSW", left_house: Date.new(2000, 1, 1)) }

      it do
        expect(helper.member_type_party_place_sentence(member)).to eq 'Former <span class="org">Pool</span> <span class="title">Senator for <span class="electorate">NSW</span></span>'
      end
    end
  end

  describe "#card_member_image" do
    it "shows the portrait when there is one" do
      member = build_stubbed(:member, person: build_stubbed(:person, large_image_url: "https://example.com/l.jpg"))

      expect(helper.card_member_image(member, :large)).to include("/system/portraits/large/#{member.person.id}.jpg")
    end

    it "falls back to a placeholder at the same size rather than leaving a hole" do
      member = build_stubbed(:member, person: build_stubbed(:person, large_image_url: nil, small_image_url: nil))

      html = helper.card_member_image(member, :large)
      expect(html).to include("generic-person")
      expect(html).to include('width="88" height="118"')
    end
  end
end

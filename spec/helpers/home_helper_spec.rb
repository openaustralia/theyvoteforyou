require 'spec_helper'

describe HomeHelper, type: :helper do
  describe "#search_people_form_placeholder_text" do
    context "when there are no people" do
      it "is nil" do
        expect(helper.search_people_form_placeholder_text).to eq nil
      end
    end

    context "when there are people" do
      before do
        member = create :member, first_name: "Magic", last_name: "Jane"
        allow(Member).to receive(:random_postcode).and_return "1234"
      end

      it "uses the details of a random person" do
        expect(helper.search_people_form_placeholder_text).to eql "e.g. 1234 or Magic Jane"
      end
    end
  end
end

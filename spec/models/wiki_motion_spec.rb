# frozen_string_literal: true

require "spec_helper"

describe WikiMotion do
  let(:division) { create(:division, name: "Original name", motion: "Original motion") }

  describe "#previous_title" do
    context "when there is no earlier edit" do
      subject(:edit) { create(:wiki_motion, division: division, title: "First title") }

      it "returns the original name" do
        expect(edit.previous_title).to eq "Original name"
      end
    end

    context "when there is an earlier edit" do
      subject(:edit) { create(:wiki_motion, division: division, title: "Second title", created_at: 2.days.ago) }

      before { create(:wiki_motion, division: division, title: "First title", created_at: 3.days.ago) }

      it "returns the title of the earlier edit" do
        expect(edit.previous_title).to include "First title"
      end
    end
  end

  describe "#previous_description" do
    context "when there is no earlier edit" do
      subject(:edit) { create(:wiki_motion, division: division, description: "First description") }

      it "returns the original motion" do
        expect(edit.previous_description).to eq "Original motion"
      end
    end

    context "when there is an earlier edit" do
      subject(:edit) { create(:wiki_motion, division: division, description: "Second description", created_at: 2.days.ago) }

      before { create(:wiki_motion, division: division, description: "First description", created_at: 3.days.ago) }

      it "returns the description of the earlier edit" do
        expect(edit.previous_description).to include "First description"
      end
    end
  end
end

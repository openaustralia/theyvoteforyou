# frozen_string_literal: true

require "spec_helper"

describe WikiMotion do
  let(:division) { create(:division, name: "Original name", motion: "Original motion") }

  describe "validations" do
    subject(:edit) { build(:wiki_motion, ai_assisted: ai_assisted, ai_model: ai_model) }

    context "when AI assisted and no model is given" do
      let(:ai_assisted) { true }
      let(:ai_model) { " " }

      it { is_expected.not_to be_valid }
    end

    context "when AI assisted and a model is given" do
      let(:ai_assisted) { true }
      let(:ai_model) { "Claude Sonnet 5.5" }

      it { is_expected.to be_valid }
    end

    context "when the model name is too long" do
      let(:ai_assisted) { true }
      let(:ai_model) { "x" * 101 }

      it { is_expected.not_to be_valid }
    end

    context "when AI wasn't used and no model is given" do
      let(:ai_assisted) { false }
      let(:ai_model) { nil }

      it { is_expected.to be_valid }
    end

    context "when AI use is unknown" do
      let(:ai_assisted) { nil }
      let(:ai_model) { nil }

      it { is_expected.to be_valid }
    end
  end

  describe "#ai_model" do
    subject { create(:wiki_motion, ai_assisted: ai_assisted, ai_model: ai_model).ai_model }

    context "when AI assisted with stray whitespace in the name" do
      let(:ai_assisted) { true }
      let(:ai_model) { "  Claude   Sonnet 5.5 " }

      it { is_expected.to eq "Claude Sonnet 5.5" }
    end

    context "when AI wasn't used but a model was submitted" do
      let(:ai_assisted) { false }
      let(:ai_model) { "Claude Sonnet 5.5" }

      it { is_expected.to be_nil }
    end
  end

  describe "#ai_assisted" do
    it "is nil unless recorded, so unknown isn't mistaken for no" do
      expect(create(:wiki_motion).ai_assisted).to be_nil
    end
  end

  describe ".ai_models" do
    subject { described_class.ai_models }

    context "with models used on several summaries" do
      before do
        create(:wiki_motion, ai_assisted: true, ai_model: "B model")
        create(:wiki_motion, ai_assisted: true, ai_model: "A model")
        create(:wiki_motion, ai_assisted: true, ai_model: "A model")
        create(:wiki_motion)
      end

      it { is_expected.to eq ["A model", "B model"] }
    end
  end

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

# frozen_string_literal: true

require "spec_helper"

describe PolicyPersonDistancesHelper, type: :helper do
  describe ".category_words_sentence" do
    it { expect(helper.category_words_sentence(:for3)).to eq "voted consistently for" }
    it { expect(helper.category_words_sentence(:never)).to eq "has never voted on" }
    # The capitalising here is a bit of a hack
    # TODO: Do this more consistently
    it { expect(helper.category_words_sentence(:not_enough)).to eq "We can't say anything concrete about how they voted on" }

    it do
      expect(helper.category_words_sentence(:never, person: "Christine Milne")).to eq "Christine Milne has never voted on"
    end

    it do
      expect(helper.category_words_sentence(:never, person: "Christine Milne", policy: "dusty ponies being dusty")).to eq "Christine Milne has never voted on dusty ponies being dusty"
    end

    it do
      expect(helper.category_words_sentence(:for3, person: "Christine Milne")).to eq "Christine Milne voted consistently for"
    end

    it do
      expect(helper.category_words_sentence(:not_enough, person: "Christine Milne")).to eq "We can't say anything concrete about how Christine Milne voted on"
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

describe PolicyPersonDistancesHelper, type: :helper do
  describe ".category_words" do
    it { expect(helper.category_words(:for3)).to eq "voted consistently for" }
    it { expect(helper.category_words(:never)).to eq "has never voted on" }
    it { expect(helper.category_words(:not_enough)).to eq "has not voted enough to determine a position on" }
  end
end

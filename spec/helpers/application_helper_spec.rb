# frozen_string_literal: true

require "spec_helper"

describe ApplicationHelper, type: :helper do
  describe "#fraction_to_percentage_display" do
    it "displays exactly 1 as 100%" do
      expect(helper.fraction_to_percentage_display(1)).to eq "100%"
    end

    it "displays exactly 0 as 0%" do
      expect(helper.fraction_to_percentage_display(0)).to eq "0%"
    end

    it "rounds percentages to the nearest integer" do
      expect(helper.fraction_to_percentage_display(0.2245)).to eq "22%"
    end

    it "shows more precision on numbers near to 0% that are not exactly 0%" do
      expect(helper.fraction_to_percentage_display(0.00456)).to eq "0.5%"
    end

    it "shows more precision on numbers near to 0% that are not exactly 0% (example 2)" do
      expect(helper.fraction_to_percentage_display(0.0000001)).to eq "0.00001%"
    end

    it "shows less precision once rounded number would not be 0%" do
      expect(helper.fraction_to_percentage_display(0.00556)).to eq "1%"
    end

    it "shows more precision on numbers near to 100% that are not exactly 100%" do
      expect(helper.fraction_to_percentage_display(0.9956)).to eq "99.6%"
    end

    it "shows more precision on numbers near to 100% that are not exactly 100% (example 2)" do
      expect(helper.fraction_to_percentage_display(0.9999999)).to eq "99.99999%"
    end

    it "shows less precision once rounded number would be different than 100%" do
      expect(helper.fraction_to_percentage_display(0.9946)).to eq "99%"
    end
  end

  describe "#list_in_words" do
    it { expect(helper.list_in_words(%w[])).to eq "" }
    it { expect(helper.list_in_words(%w[foo])).to eq "foo" }
    it { expect(helper.list_in_words(%w[foo bar])).to eq "foo and bar" }
    it { expect(helper.list_in_words(%w[foo bar twist])).to eq "foo, bar and twist" }
    it { expect(helper.list_in_words(%w[foo bar twist wibble])).to eq "foo, bar, twist and wibble" }

    it "escapes html with one word" do
      expect(helper.list_in_words(%w[<foo>])).to eq "&lt;foo&gt;"
    end

    it "escapes html with several words" do
      expect(helper.list_in_words(%w[<foo> <bar> <twist>])).to eq "&lt;foo&gt;, &lt;bar&gt; and &lt;twist&gt;"
    end

    it "can use a different word to join the list" do
      expect(helper.list_in_words(%w[foo bar twist], "or")).to eq "foo, bar or twist"
    end
  end
end

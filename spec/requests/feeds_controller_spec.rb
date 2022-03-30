# frozen_string_literal: true

require "spec_helper"

describe FeedsController, type: :request do
  include HTMLCompareHelper
  include_context "with fixtures"

  describe "#mp-info" do
    before do
      division_representatives_2013_03_14_1
      # Representatives
      member_tony_abbott
      member_john_howard
      member_john_alexander
      member_roger_price
      # Senate
      member_disagreeable_curmudgeon
      member_surly_nihilist
      member_judith_adams
      member_christine_milne
      member_christopher_back
    end

    it { compare_static("/feeds/mp-info.xml", format: "xml") }
    it { compare_static("/feeds/mp-info.xml?house=senate", format: "xml") }
  end

  describe "#mpdream-info" do
    before do
      member_tony_abbott
      member_kevin_rudd
      member_john_alexander
      policy1_tony_abbott
      policy1_kevin_rudd
      policy1_john_alexander
    end

    it { compare_static("/feeds/mpdream-info.xml?id=1", format: "xml") }
  end
end

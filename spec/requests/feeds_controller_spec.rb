# frozen_string_literal: true

require "spec_helper"

describe FeedsController, type: :request do
  include HTMLCompareHelper
  include_context "with fixtures"

  before do
    add_new_fixtures
  end

  describe "#mp-info" do
    it { compare_static("/feeds/mp-info.xml", format: "xml") }
    it { compare_static("/feeds/mp-info.xml?house=senate", format: "xml") }
  end

  describe "#mpdream-info" do
    it { compare_static("/feeds/mpdream-info.xml?id=1", format: "xml") }
  end
end

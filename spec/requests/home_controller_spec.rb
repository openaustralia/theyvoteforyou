# frozen_string_literal: true

require "spec_helper"
# Compare results of rendering pages via rails and via the old php app

describe HomeController, type: :request do
  include HTMLCompareHelper
  include_context "with fixtures"

  before do
    add_new_fixtures
  end

  it "#index" do
    compare_static("/")
  end

  it "#faq" do
    compare_static("/help/faq")
  end

  describe "#search" do
    it { compare_static("/search") }

    # Goes direct to MP page (only one MP covered by this postcode)
    it do
      VCR.use_cassette("openaustralia_postcode_api") do
        get("/search?query=2088")
        expect(response).to redirect_to("/people/representatives/warringah/tony_abbott")
      end
    end

    # Two electorates cover this postcode
    it do
      VCR.use_cassette("openaustralia_postcode_api") { compare_static("/search?query=2042") }
    end

    # Bad postcode
    it do
      VCR.use_cassette("openaustralia_postcode_api") { compare_static("/search?query=0000") }
    end
  end
end

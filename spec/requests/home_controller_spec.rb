# frozen_string_literal: true

require "spec_helper"
# Compare results of rendering pages via rails and via the old php app

describe HomeController, type: :request do
  include HTMLCompareHelper
  include_context "with fixtures"

  it "#index" do
    member_tony_abbott
    member_john_alexander
    member_christopher_back
    member_christine_milne
    compare_static("/")
  end

  it "#faq" do
    member_tony_abbott
    member_kevin_rudd
    member_christine_milne
    member_john_howard
    member_maxine_mckew
    member_john_alexander
    member_christopher_back
    member_judith_adams
    member_paul_zammit
    member_disagreeable_curmudgeon
    member_surly_nihilist
    member_roger_price
    division_representatives_2013_03_14_1
    division_senate_2013_03_14_1
    division_representatives_2006_12_06_3
    division_senate_2009_11_25_8
    division_senate_2009_11_30_8
    division_senate_2009_12_30_8
    policy1
    policy2
    policy3
    compare_static("/help/faq")
  end

  describe "#search" do
    it { compare_static("/search") }

    # Goes direct to MP page (only one MP covered by this postcode)
    it do
      member_tony_abbott
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

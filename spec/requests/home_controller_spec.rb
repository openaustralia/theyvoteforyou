require 'spec_helper'
# Compare results of rendering pages via rails and via the old php app

describe HomeController, type: :request do
  include HTMLCompareHelper
  fixtures :all

  # TODO: Do we really need this test?
  #       The homepage was written from scratch
  #       at the end of the rails upgrade and doesn't include complex
  #       behaviour that could easily regress.
  it "#index" do
    compare_static("/")
  end

  # TODO: Do we really need this test?
  #       The only dynamic content on this page is the paragraph with
  #       summary data. We could extract that to a helper and write specific
  #       tests to guard from regression.
  it "#faq" do
    compare_static("/faq.php")
  end

  describe "#search" do
    # TODO: Do we really need this test?
    #       The redirect is already covered in spec/routing/redirects_spec.rb:246
    #       Aside from that, this is a static page with no complex logic to regress.
    it {compare_static("/search.php")}

    # Goes direct to MP page (only one MP covered by this postcode)
    it do
      VCR.use_cassette('openaustralia_postcode_api') {compare_static("/search.php?query=2088&button=Search")}
    end
    # Two electorates cover this postcode
    it do
      VCR.use_cassette('openaustralia_postcode_api') {compare_static("/search.php?query=2042&button=Search")}
    end
    # Bad postcode
    it do
      VCR.use_cassette('openaustralia_postcode_api') {compare_static("/search.php?query=0000&button=Search")}
    end
  end
end

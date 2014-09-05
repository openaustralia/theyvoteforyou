require 'spec_helper'
# Compare results of rendering pages via rails and via the old php app

describe HomeController, :type => :request do
  include HTMLCompareHelper
  fixtures :all

  it "#index" do
    compare_static("/")
  end

  it "#faq" do
    compare_static("/faq.php")
  end

  describe "#search" do
    it {compare_static("/search.php")}

    # Goes direct to MP page (only one MP covered by this postcode)
    it {compare_static("/search.php?query=2088&button=Search")}
    # Two electorates cover this postcode
    it {compare_static("/search.php?query=2042&button=Search")}
    # Bad postcode
    it {compare_static("/search.php?query=0000&button=Search")}

    it {compare_static("/search.php?query=Tony+Abbott&button=Search")}
    it {compare_static("/search.php?query=Kevin&button=Search")}
    it {compare_static("/search.php?query=supplementary+explanatory+memorandum&button=Search")}
    it {compare_static("/search.php?query=This+is+some+test+text&button=Search")}
    it {compare_static("/search.php?query=Wa-pa-pa-pa-pa-pow&button=Search")}

    it {compare_static("/search.php?query=2088&button=Search")}
    it {compare_static("/search.php?query=2042&button=Submit")}
    it {compare_static("/search.php?query=0000&button=Search")}
    it {compare_static("/search.php?query=Tony+Abbott&button=Submit")}
    it {compare_static("/search.php?query=Kevin&button=Search")}
    it {compare_static("/search.php?query=supplementary+explanatory+memorandum&button=Submit")}
    it {compare_static("/search.php?query=This+is+some+test+text&button=Submit")}
    it {compare_static("/search.php?query=Wa-pa-pa-pa-pa-pow&button=Submit")}
  end
end

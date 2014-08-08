require 'spec_helper'
# Compare results of rendering pages via rails and via the old php app

describe HomeController, :type => :request do
  include HTMLCompareHelper
  fixtures :all

  it "#index" do
    compare("/")
  end

  it "#faq" do
    compare("/faq.php")
  end

  it "#search" do
    compare("/search.php")

    # Goes direct to MP page (only one MP covered by this postcode)
    compare("/search.php?query=2088&button=Search")
    # Two electorates cover this postcode
    compare("/search.php?query=2042&button=Search")
    # Bad postcode
    compare("/search.php?query=0000&button=Search")
    # No MPs in our fixutres
    compare("/search.php?query=2037&button=Search")

    compare("/search.php?query=Tony+Abbott&button=Search")
    compare("/search.php?query=Kevin&button=Search")
    compare("/search.php?query=supplementary+explanatory+memorandum&button=Search")
    compare("/search.php?query=This+is+some+test+text&button=Search")
    compare("/search.php?query=Wa-pa-pa-pa-pa-pow&button=Search")

    compare("/search.php?query=2088&button=Search")
    compare("/search.php?query=2042&button=Submit")
    compare("/search.php?query=0000&button=Search")
    compare("/search.php?query=Tony+Abbott&button=Submit")
    compare("/search.php?query=Kevin&button=Search")
    compare("/search.php?query=supplementary+explanatory+memorandum&button=Submit")
    compare("/search.php?query=This+is+some+test+text&button=Submit")
    compare("/search.php?query=Wa-pa-pa-pa-pa-pow&button=Submit")
  end
end

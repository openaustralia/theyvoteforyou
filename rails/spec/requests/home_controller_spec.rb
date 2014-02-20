require 'spec_helper'
# Compare results of rendering pages via rails and via the old php app

describe HomeController do
  include HTMLCompareHelper
  fixtures :all

  it "#index" do
    compare("/")
  end

  it "#faq" do
    compare("/faq.php")
  end
end

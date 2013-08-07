require 'spec_helper'
# Compare results of rendering pages via rails and via the old php app

describe HomeController do
  include HTMLCompareHelper
  fixtures :members, :member_infos, :divisions, :division_infos, :whips, :votes

  it "#index" do
    compare("/")
  end

  it "#faq" do
    compare("/faq.php")
  end
end

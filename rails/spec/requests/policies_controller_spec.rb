require 'spec_helper'
# Compare results of rendering pages via rails and via the old php app

describe PoliciesController do
  include HTMLCompareHelper
  fixtures :all

  it "#index" do
    compare("/policies.php")
  end

  it "#show" do
    compare("/policy.php?id=1")
    # compare("/policy.php?id=1&display=motions")
    # compare("/policy.php?id=1&display=editdefinition")
  end
end

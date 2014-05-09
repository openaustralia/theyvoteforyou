require 'spec_helper'
# Compare results of rendering pages via rails and via the old php app

describe PoliciesController do
  include HTMLCompareHelper
  fixtures :all

  it "#index" do
    compare("/policies.php")
  end

  describe "#show" do
    it { compare("/policy.php?id=1") }
    # compare("/policy.php?id=1&display=motions")
    # compare("/policy.php?id=1&display=editdefinition")
    it { compare("/policy.php?id=1&display=editdefinition", true) }

    it { compare("/policy.php?id=2") }
    # compare("/policy.php?id=2&display=motions")
    # compare("/policy.php?id=2&display=editdefinition")
  end
end

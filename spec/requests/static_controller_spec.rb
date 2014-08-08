require 'spec_helper'
# Compare results of rendering pages via rails and via the old php app

describe StaticController, :type => :request do
  include HTMLCompareHelper
  fixtures :all

  it "#code" do
    compare("/project/code.php")
  end

  it "#data" do
    compare("/project/data.php")
  end

  it "#research" do
    compare("/project/research.php")
  end
 end

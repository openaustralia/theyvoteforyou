require 'spec_helper'
# Compare results of rendering pages via rails and via the old php app

describe StaticController do
  include HTMLCompareHelper
  fixtures :all

  it "#code" do
    compare_static("/project/code.php")
  end

  it "#data" do
    compare_static("/project/data.php")
  end

  it "#research" do
    compare_static("/project/research.php")
  end
 end

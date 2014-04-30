require 'spec_helper'

describe AccountController do
  include HTMLCompareHelper
  fixtures :all

  it '#settings' do
    compare('/account/settings.php')
  end
end

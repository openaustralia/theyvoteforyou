require 'spec_helper'

describe AccountController do
  include HTMLCompareHelper
  fixtures :all

  describe '#settings' do
    it 'shows the settings page when logged in', focus: true do
      compare_static '/account/settings.php', true
    end
  end
end

require 'spec_helper'

describe AccountController do
  include HTMLCompareHelper
  fixtures :all

  it '#settings' do
    compare('/account/settings.php')
  end

  it 'logs in with valid credentials' do
    compare_post '/account/settings.php', submit: 'Login to Public Whip', user_name: 'henare', password: 'password'
  end
end

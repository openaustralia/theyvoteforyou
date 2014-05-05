require 'spec_helper'

describe AccountController do
  include HTMLCompareHelper
  fixtures :all

  it '#settings' do
    compare('/account/settings.php')
  end

  it 'logs in with valid credentials' do
    compare_post '/account/settings.php', false, submit: 'Login to Public Whip', user_name: 'henare', password: 'password'
  end

  it "doesn't log in with invalid credentials" do
    compare_post '/account/settings.php', false, submit: 'Login to Public Whip', user_name: 'new_user', password: 'letmein'
  end

  it '#logout' do
    compare '/account/logout.php'
  end

  describe '#change_password' do
    it { compare '/account/changepass.php' }
    it { compare '/account/changepass.php', true }
  end
end

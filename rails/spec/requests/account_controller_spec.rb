require 'spec_helper'

describe AccountController do
  include HTMLCompareHelper
  fixtures :all

  it '#settings' do
    compare('/account/settings.php')
  end

  context 'without redirects' do
    it 'logs in with valid credentials' do
      compare_post '/account/settings.php', submit: 'Login to Public Whip', user_name: 'henare', password: 'password'
    end

    it "doesn't log in with invalid credentials" do
      compare_post '/account/settings.php', submit: 'Login to Public Whip', user_name: 'new_user', password: 'letmein'
    end
  end

  context 'with redirects' do
    it 'logs in with valid credentials' do
      compare_post '/account/settings.php?r=/', submit: 'Login to Public Whip', user_name: 'henare', password: 'password'
    end

    it "doesn't log in with invalid credentials" do
      compare_post '/account/settings.php?r=/', submit: 'Login to Public Whip', user_name: 'new_user', password: 'letmein'
    end
  end
end

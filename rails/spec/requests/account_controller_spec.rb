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
    let(:url) { '/account/changepass.php' }

    it { compare url }
    it { compare url, true }

    context "new passwords don't match" do
      it { compare_post url, true, submit: 'Change My Password', new_password1: 'foobar', new_password2: 'barfoo' }
    end
  end
end

require 'spec_helper'

describe AccountController do
  include HTMLCompareHelper
  fixtures :all

  describe '#settings' do
    it { compare('/account/settings.php') }

    it 'logs in with valid credentials' do
      compare_post '/account/settings.php', false, submit: 'Login to Public Whip', user_name: 'henare', password: 'password'
    end

    it "doesn't log in with invalid credentials" do
      compare_post '/account/settings.php', false, submit: 'Login to Public Whip', user_name: 'new_user', password: 'letmein'
    end
  end

  it '#logout' do
    compare '/account/logout.php'
  end

  describe '#change_password' do
    let(:url) { '/account/changepass.php' }

    it { compare url }
    it { compare url, true }

    context "new passwords don't match" do
      it { compare_post url, true, submit: 'Change My Password', old_password: 'password', new_password1: 'some_password', new_password2: 'another_password' }
    end

    context "old password is wrong" do
      it { compare_post url, true, submit: 'Change My Password', old_password: 'wrong_password', new_password1: 'foobar', new_password2: 'foobar' }
    end

    it "changes the password if the details are correct" do
      User.any_instance.stub :change_password
      compare_post url, true, submit: 'Change My Password', change_user_name: 'henare', old_password: 'password', new_password1: 'new_password', new_password2: 'new_password'
    end
  end

  describe '#addpolicy' do
    let(:url) { '/account/addpolicy.php' }

    # The PHP app does something really silly when we're not logged in,
    # it turns this page into a login page. We're going to redirect to the
    # login page instead (which redirects back here after login) so disabling
    # this test
    #it { compare url }

    it { compare url, true }
  end
end

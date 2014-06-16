require 'spec_helper'

describe AccountController do
  include HTMLCompareHelper
  fixtures :all

  describe '#settings' do
    it 'shows the settings page when logged in', focus: true do
      compare '/account/settings.php', true
    end
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
end

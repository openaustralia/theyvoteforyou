# frozen_string_literal: true

require "spec_helper"

describe "User profile", type: :feature do
  before do
    # TODO: Remove this hack to delete fixtures
    Member.delete_all
    User.delete_all

    create :member
  end

  let(:user) { create(:user, confirmed_at: Time.zone.now) }

  it "changing name without changing password" do
    visit "/"
    click_link "Log in"
    within "#new_user" do
      fill_in "Email", with: user.email
      fill_in "Password", with: user.password
    end
    click_button "Log in"
    expect(page).to have_content "Welcome!"
    click_link "Edit profile"
    within "#edit_user" do
      fill_in "Username", with: "Henare Degan, Esquire"
      fill_in "Current password", with: user.password
    end
    click_button "Update"
    expect(page).to have_content "You updated your account successfully."
    expect(user.reload.name).to eql "Henare Degan, Esquire"
  end
end

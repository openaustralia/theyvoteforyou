# frozen_string_literal: true

require "spec_helper"

describe "Signing up", type: :feature do
  before do
    create :member
  end

  it "with valid details" do
    visit "/"
    click_link "Sign up"
    expect(page).to have_content "Sign up to help unlock parliament"
    within("#new_user") do
      fill_in "Email", with: "henare@oaf.org.au"
      fill_in "Username", with: "Henare Degan"
      fill_in "Password", with: "password"
    end
    click_button "Sign up"
    expect(page).to have_content "now check your inbox"
    expect(unread_emails_for("henare@oaf.org.au").size).to be 1
    open_last_email_for("henare@oaf.org.au")
    expect(current_email).to have_subject("Confirm your email address")
    click_email_link_matching(/confirm/)
    expect(find(".account-nav")).to have_content("Henare Degan")
    expect(page).to have_content "Welcome!"
  end
end

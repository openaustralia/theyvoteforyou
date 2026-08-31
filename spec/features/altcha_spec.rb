# frozen_string_literal: true

require "spec_helper"

describe "The ALTCHA spam check on the sign up form", type: :feature do
  before do
    Flipper.enable(:altcha)
    Flipper.enable(:altcha_enforce)
  end

  def fill_in_the_form
    visit "/users/sign_up"
    within("#new_user") do
      fill_in "Email", with: "newcomer@example.org"
      fill_in "Username", with: "Pat Placeholder"
      fill_in "Password", with: "correct horse battery"
    end
  end

  # rack-test is a perfect stand-in for somebody without JavaScript: it renders the widget and
  # never runs it. This is the exclusion the ADR accepts, pinned so nobody can quietly widen it.
  context "without JavaScript" do
    it "turns the person away, and tells them what to do about it" do
      fill_in_the_form
      click_on "Sign up"
      expect(page).to have_text "needs JavaScript turned on"
      expect(page).to have_text "contact@theyvoteforyou.org.au"
    end

    it "keeps what they typed, so a retry is not starting over" do
      fill_in_the_form
      click_on "Sign up"
      expect(page).to have_field("Email", with: "newcomer@example.org")
      expect(page).to have_field("Username", with: "Pat Placeholder")
    end

    it "creates no account" do
      fill_in_the_form
      expect { click_on "Sign up" }.not_to change(User, :count)
    end
  end

  # The one example that runs a real browser. Everything else in this feature tests code we wrote;
  # this tests the thing we cannot verify any other way, which is that the widget's JSON and the
  # Ruby gem's canonical JSON agree byte for byte. If they ever stop agreeing, all four
  # authentication forms reject everybody at once, so it is worth one slow example.
  context "with JavaScript", :js do
    it "solves the challenge and lets the person sign up" do
      fill_in_the_form
      # Wait on the hidden field rather than on any widget text, which changes between versions.
      expect(page).to have_selector("input[name='altcha'][value]", visible: :hidden, wait: 30)
      click_on "Sign up"
      expect(page).to have_text "now check your inbox"
      expect(page).to have_no_text "needs JavaScript turned on"
    end
  end
end

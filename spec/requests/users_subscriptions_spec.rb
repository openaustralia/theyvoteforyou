# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Subscriptions page", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:confirmed_user, email: "subscriber@example.org") }
  let(:other_user) { create(:confirmed_user, email: "other@example.org") }

  def suppress(address, at: Time.zone.local(2026, 3, 4, 10))
    EmailSuppression.suppress!(address, reason: :hard_bounce, at: at)
  end

  it "tells a person with a suppressed address their updates are paused, since when, and how to resume" do
    suppress("subscriber@example.org")
    sign_in user

    get user_subscriptions_path(user)

    expect(response.body).to include("email-suppression-notice", "since 4 March 2026, so your policy update emails are paused",
                                     edit_user_registration_path, new_user_password_path)
  end

  it "shows nothing to a person whose address has no suppression" do
    sign_in user

    get user_subscriptions_path(user)

    expect(response.body).not_to include("email-suppression-notice")
  end

  it "shows nothing once the suppression has been lifted" do
    suppress("subscriber@example.org")
    EmailSuppression.lift!("subscriber@example.org")
    sign_in user

    get user_subscriptions_path(user)

    expect(response.body).not_to include("email-suppression-notice")
  end

  it "shows nothing about another person's mail when viewing their page" do
    suppress("other@example.org")
    sign_in user

    get user_subscriptions_path(other_user)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("email-suppression-notice")
  end

  it "does not show the notice for the new address after the person changes it" do
    suppress("subscriber@example.org")
    user.update!(email: "new@example.org")
    user.confirm
    sign_in user.reload

    get user_subscriptions_path(user)

    expect(response.body).not_to include("email-suppression-notice")
  end

  describe "resuming with a password reset, from the notice" do
    before do
      suppress("subscriber@example.org")
      sign_in user
    end

    it "lets the signed-in person open the password reset form the notice links to" do
      get new_user_password_path

      expect(response).to have_http_status(:ok)
    end

    it "lets the signed-in person complete the reset, which lifts the suppression" do
      token = user.send_reset_password_instructions

      put "/users/password",
          params: { user: { reset_password_token: token, password: "a new password", password_confirmation: "a new password" } }

      expect(EmailSuppression.suppressed?("subscriber@example.org")).to be(false)
    end
  end
end

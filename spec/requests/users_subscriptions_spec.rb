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
end

# frozen_string_literal: true

require "spec_helper"

# A person whose address was suppressed resumes policy updates by proving the mailbox works again.
RSpec.describe "Lifting an email suppression", type: :request do
  let(:address) { "resumer@example.org" }
  let(:user) { create(:user, email: address) }
  let(:editor) { create(:user, name: "Wibble") }
  let(:policy) do
    PaperTrail.request.whodunnit = editor.id
    create(:policy, name: "red being a nice colour")
  end

  before do
    user
    policy
    EmailSuppression.suppress!(address, reason: :hard_bounce, postal_event: "MessageDeliveryFailed")
    ActionMailer::Base.deliveries.clear
  end

  def alerts_delivered_to(address)
    AlertMailer.policy_updated(policy, policy.versions.last, user).deliver_now
    ActionMailer::Base.deliveries.count { |mail| mail.to.include?(address) && mail["X-Postal-Tag"].value == "alert" }
  end

  it "still sends the confirmation email to a suppressed address" do
    user.send_confirmation_instructions

    expect(ActionMailer::Base.deliveries.map { |m| [m.to, m["X-Postal-Tag"].value] }).to eq([[[address], "confirmation"]])
  end

  it "still sends the password reset email to a suppressed address" do
    user.send_reset_password_instructions

    expect(ActionMailer::Base.deliveries.map { |m| [m.to, m["X-Postal-Tag"].value] }).to eq([[[address], "password"]])
  end

  it "lifts the suppression when the confirmation link is followed" do
    get "/users/confirmation", params: { confirmation_token: user.confirmation_token }

    expect(EmailSuppression.suppressed?(address)).to be(false)
  end

  it "keeps the suppression when the confirmation token is wrong" do
    get "/users/confirmation", params: { confirmation_token: "wrong" }

    expect(EmailSuppression.suppressed?(address)).to be(true)
  end

  it "lifts the suppression when a password reset is completed" do
    token = user.send_reset_password_instructions

    put "/users/password",
        params: { user: { reset_password_token: token, password: "a new password", password_confirmation: "a new password" } }

    expect(EmailSuppression.suppressed?(address)).to be(false)
  end

  it "keeps the suppression when a password reset fails" do
    token = user.send_reset_password_instructions

    put "/users/password",
        params: { user: { reset_password_token: token, password: "a new password", password_confirmation: "different" } }

    expect(EmailSuppression.suppressed?(address)).to be(true)
  end

  it "resumes policy updates after a lift, without anyone re-subscribing" do
    policy.watches.create!(user: user)
    expect(alerts_delivered_to(address)).to eq(0)

    get "/users/confirmation", params: { confirmation_token: user.confirmation_token }

    expect(alerts_delivered_to(address)).to eq(1)
    expect(user.reload.watches.count).to eq(1)
  end

  it "keeps the row of a lifted suppression, as history" do
    get "/users/confirmation", params: { confirmation_token: user.confirmation_token }

    expect(EmailSuppression.where(address: address).sole.lifted_at).to be_present
  end

  context "when the person changes the address on their account" do
    let(:confirmed) { create(:confirmed_user, email: "old@example.org") }

    before do
      confirmed
      ActionMailer::Base.deliveries.clear
      EmailSuppression.suppress!("old@example.org", reason: :hard_bounce)
      confirmed.update!(email: "new@example.org")
    end

    it "does not suppress the new address" do
      expect(EmailSuppression.suppressed?("new@example.org")).to be(false)
    end

    it "sends the reconfirmation email to the new address" do
      expect(ActionMailer::Base.deliveries.map(&:to)).to eq([["new@example.org"]])
    end

    it "lifts a suppression on the new address when its reconfirmation link is followed, and only that one" do
      EmailSuppression.suppress!("new@example.org", reason: :hard_bounce)

      get "/users/confirmation", params: { confirmation_token: confirmed.reload.confirmation_token }

      expect(EmailSuppression.suppressed?("new@example.org")).to be(false)
      expect(EmailSuppression.suppressed?("old@example.org")).to be(true)
    end
  end
end

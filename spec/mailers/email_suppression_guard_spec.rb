# frozen_string_literal: true

require "spec_helper"

# Sends real mail through the test delivery method and reads ActionMailer::Base.deliveries, so nothing leaves the
# machine. The guard under test is SuppressedAlertInterceptor.
RSpec.describe "Email suppression guard" do # rubocop:disable RSpec/DescribeClass
  let(:editor) { create(:user, name: "Wibble") }
  let(:policy) do
    PaperTrail.request.whodunnit = editor.id
    create(:policy, name: "red being a nice colour")
  end
  let(:subscriber) { create(:confirmed_user, email: "subscriber@example.org") }

  def send_policy_update(user)
    AlertMailer.policy_updated(policy, policy.versions.last, user).deliver_now
  end

  def suppress(address)
    EmailSuppression.suppress!(address, reason: :hard_bounce, postal_event: "MessageDeliveryFailed")
  end

  def delivered_to(address)
    ActionMailer::Base.deliveries.select { |mail| mail.to.include?(address) }
  end

  # Creating a user sends Devise's own confirmation email, so create the records first and then start from nothing sent.
  before do
    subscriber
    policy
    ActionMailer::Base.deliveries.clear
  end

  describe "policy update emails" do
    it "are delivered to an address with no suppression" do
      send_policy_update(subscriber)

      expect(delivered_to("subscriber@example.org").size).to eq(1)
    end

    it "are not delivered to a suppressed address" do
      suppress("subscriber@example.org")

      send_policy_update(subscriber)

      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it "are still caught when the suppressed address differs in case or whitespace" do
      suppress("  Subscriber@Example.ORG ")

      send_policy_update(subscriber)

      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it "are still caught when the suppressed address came with a display name" do
      suppress("Some Person <subscriber@example.org>")

      send_policy_update(subscriber)

      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it "are delivered again once the suppression is lifted" do
      suppress("subscriber@example.org")
      EmailSuppression.lift!("subscriber@example.org")

      send_policy_update(subscriber)

      expect(delivered_to("subscriber@example.org").size).to eq(1)
    end

    it "carry the alert tag" do
      send_policy_update(subscriber)

      expect(ActionMailer::Base.deliveries.last["X-Postal-Tag"].value).to eq("alert")
    end

    it "do not stop the rest of the job when one subscriber is suppressed" do
      other = create(:confirmed_user, email: "other@example.org")
      policy.watches.create!(user: subscriber)
      policy.watches.create!(user: other)
      suppress("subscriber@example.org")

      AlertWatchesJob.perform_now(policy, policy.versions.last)

      expect(delivered_to("other@example.org").size).to eq(1)
      expect(delivered_to("subscriber@example.org")).to be_empty
    end

    it "leave the subscriptions of a suppressed address in place" do
      policy.watches.create!(user: subscriber)
      suppress("subscriber@example.org")

      AlertWatchesJob.perform_now(policy, policy.versions.last)

      expect(subscriber.reload.watches.count).to eq(1)
    end
  end

  describe "mail the person asked for" do
    before { suppress("subscriber@example.org") }

    it "sends the confirmation email to a suppressed address, tagged confirmation" do
      DeviseMailer.confirmation_instructions(subscriber, "token").deliver_now

      mail = delivered_to("subscriber@example.org").sole
      expect(mail["X-Postal-Tag"].value).to eq("confirmation")
    end

    it "sends the password reset email to a suppressed address, tagged password" do
      DeviseMailer.reset_password_instructions(subscriber, "token").deliver_now

      mail = delivered_to("subscriber@example.org").sole
      expect(mail["X-Postal-Tag"].value).to eq("password")
    end

    it "tags any other Devise email notice" do
      DeviseMailer.password_change(subscriber).deliver_now

      expect(delivered_to("subscriber@example.org").sole["X-Postal-Tag"].value).to eq("notice")
    end
  end

  describe "suppressions" do
    it "keep one active row per address, however many times it is reported" do
      first = suppress("subscriber@example.org")
      second = suppress("SUBSCRIBER@example.org")

      expect(second).to eq(first)
      expect(EmailSuppression.count).to eq(1)
    end

    it "can't hold two active rows for one address, even if inserted directly" do
      suppress("subscriber@example.org")

      expect { EmailSuppression.create!(address: "subscriber@example.org", reason: :hard_bounce, suppressed_at: Time.current) }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "keep the row when lifted, and make a fresh active one on a later bounce" do
      first = suppress("subscriber@example.org")
      EmailSuppression.lift!("subscriber@example.org")
      second = suppress("subscriber@example.org")

      expect(first.reload.lifted_at).to be_present
      expect(second).not_to eq(first)
      expect(EmailSuppression.active.count).to eq(1)
    end

    it "keep only a short excerpt of the receiving server's reply" do
      suppression = EmailSuppression.suppress!("subscriber@example.org", reason: :hard_bounce, reply: "5.1.1 #{'x' * 1000}")

      expect(suppression.reload.reply_excerpt.length).to eq(255)
    end
  end
end

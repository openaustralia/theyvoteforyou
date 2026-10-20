# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Unsubscribe headers on email", type: :mailer do
  let(:editor) { create(:user, name: "Wibble") }
  let(:policy) do
    PaperTrail.request.whodunnit = editor.id
    create(:policy, name: "red being a nice colour")
  end
  let(:user) { create(:confirmed_user, email: "subscriber@example.org") }

  it "puts one-click unsubscribe headers on a policy update email" do
    mail = AlertMailer.policy_updated(policy, policy.versions.last, user)

    expect(mail["List-Unsubscribe"].value).to eq("<http://pw.org.au/unsubscribe/#{user.unsubscribe_token}>")
    expect(mail["List-Unsubscribe-Post"].value).to eq("List-Unsubscribe=One-Click")
  end

  it "uses an address that finds the same person" do
    mail = AlertMailer.policy_updated(policy, policy.versions.last, user)
    token = mail["List-Unsubscribe"].value[%r{/unsubscribe/([^>]+)>}, 1]

    expect(User.from_unsubscribe_token(token)).to eq(user)
  end

  it "puts none on a confirmation or password reset email" do
    mails = [DeviseMailer.confirmation_instructions(user, "token"), DeviseMailer.reset_password_instructions(user, "token")]

    expect(mails.map { |mail| [mail["List-Unsubscribe"], mail["List-Unsubscribe-Post"]] }).to all(eq([nil, nil]))
  end
end

require "rails_helper"

RSpec.describe AlertMailer, :type => :mailer do
  describe "policy_updated" do
    let(:mail) { AlertMailer.policy_updated }

    it "renders the headers" do
      expect(mail.subject).to eq("Policy updated")
      expect(mail.to).to eq(["to@example.org"])
      expect(mail.from).to eq(["from@example.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

end

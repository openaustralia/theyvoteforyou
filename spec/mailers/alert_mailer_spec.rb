# frozen_string_literal: true

require "spec_helper"

RSpec.describe AlertMailer do
  describe "policy_updated" do
    # User 1 is the one creating the policy
    let(:user1) { create(:user, name: "Wibble", id: 200) }
    let(:policy) do
      # Manually tell paper trail who made the change. This would normally be done
      # automatically
      PaperTrail.request.whodunnit = user1.id
      Timecop.freeze(Date.new(2020, 1, 1)) do
        create(:policy, name: "red being a nice colour", id: 50)
      end
    end
    # User 2 is the one being informed of the change
    let(:user2) { create(:user, email: "user2@foo.com", id: 100) }

    context "with policy created" do
      let(:mail) { described_class.policy_updated(policy, policy.versions.last, user2) }

      it "renders the headers" do
        expect(mail.subject).to eq("Policy “for red being a nice colour” updated on They Vote For You")
        expect(mail.to).to eq(["user2@foo.com"])
        expect(mail.from).to eq(["contact@theyvoteforyou.org.au"])
      end

      it "has what we expect in the text part of the email" do
        expect(mail.text_part.body.to_s.gsub("\r\n", "\n")).to eq(Rails.root.join("spec/mailers/regression/alert_mailer/email1.txt").read.gsub("\r\n", "\n"))
      end

      it "has what we expect in the html part of the email" do
        expect(mail.html_part.body.to_s.gsub("\r\n", "\n")).to include Rails.root.join("spec/mailers/regression/alert_mailer/email1.html").read.gsub("\r\n", "\n")
      end
    end

    context "with associated division text changed" do
      let(:division) { create(:division, number: 1) }
      let(:wiki_motion) { create(:wiki_motion, user: user1, division: division) }
      let(:mail) { described_class.policy_updated(policy, wiki_motion, user2) }

      it "renders the headers" do
        expect(mail.subject).to eq("Policy “for red being a nice colour” updated on They Vote For You")
        expect(mail.to).to eq(["user2@foo.com"])
        expect(mail.from).to eq(["contact@theyvoteforyou.org.au"])
      end

      it "has what we expect in the text part of the email" do
        expect(mail.text_part.body.to_s.gsub("\r\n", "\n")).to eq(Rails.root.join("spec/mailers/regression/alert_mailer/email2.txt").read.gsub("\r\n", "\n"))
      end

      it "has what we expect in the html part of the email" do
        expect(mail.html_part.body.to_s.gsub("\r\n", "\n")).to include Rails.root.join("spec/mailers/regression/alert_mailer/email2.html").read.gsub("\r\n", "\n")
      end
    end
  end
end

require "spec_helper"

describe Devise::Mailer do
  let(:user) { mock_model(User, email: "foo@bar.com", name: "Matthew Landauer") }
  describe "#confirmation_instructions" do
    let(:mail) { Devise::Mailer.confirmation_instructions(user, "abc123") }

    it { expect(mail.from).to eq ["contact@theyvoteforyou.org.au"] }
    it { expect(mail[:from].display_names).to eq ["They Vote For You"] }
    it { expect(mail.to).to eq ["foo@bar.com"] }
    it { expect(mail.subject).to eq "Confirm your email address" }
    it { expect(mail).to be_multipart }
    it { expect(mail.html_part.body.to_s).to eq File.read("spec/devise/regression/confirmation.html") }
    it { expect(mail.text_part.body.to_s).to eq File.read("spec/devise/regression/confirmation.txt") }
  end

  describe "#reset_password_instructions" do
    let(:mail) { Devise::Mailer.reset_password_instructions(user, "abc123") }

    it { expect(mail.from).to eq ["contact@theyvoteforyou.org.au"] }
    it { expect(mail[:from].display_names).to eq ["They Vote For You"] }
    it { expect(mail.to).to eq ["foo@bar.com"] }
    it { expect(mail.subject).to eq "Reset your password" }
    it { expect(mail).to be_multipart }
    it { expect(mail.html_part.body.to_s).to eq File.read("spec/devise/regression/reset.html") }
    it { expect(mail.text_part.body.to_s).to eq File.read("spec/devise/regression/reset.txt") }
  end
end

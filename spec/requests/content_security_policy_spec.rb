# frozen_string_literal: true

require "spec_helper"

# The policy is report-only for now, see https://github.com/openaustralia/theyvoteforyou/issues/1879
describe "Content Security Policy", type: :request do
  # Methods, not let, because the nonce test makes two requests in one example
  def report_only
    response.headers["Content-Security-Policy-Report-Only"]
  end

  def nonce
    report_only[/script-src[^;]*'nonce-([^']+)'/, 1]
  end

  def inline_scripts
    response.parsed_body.css("script:not([src])")
  end

  it "reports violations without blocking anything" do
    get about_path
    expect(report_only).to be_present
    expect(response.headers["Content-Security-Policy"]).to be_nil
  end

  it "allows only this site and the services it uses" do
    get about_path
    expect(report_only).to include("default-src 'self'")
    expect(report_only).to include("object-src 'none'")
    expect(report_only).to include("base-uri 'self'")
    expect(report_only).to include("script-src 'self' https://js-de.sentry-cdn.com")
  end

  it "makes a new nonce for every request" do
    get about_path
    first = nonce
    get about_path
    expect(nonce).to be_present
    expect(nonce).not_to eq first
  end

  context "when a page has inline scripts" do
    before { create(:announcement) }

    it "gives every inline script the nonce from the header" do
      get about_path
      expect(inline_scripts).not_to be_empty
      expect(inline_scripts.pluck("nonce").uniq).to eq [nonce]
    end
  end

  # The test environment has no Sentry DSN, so give the policy a report address for these examples
  context "when violation reports are sent to Sentry" do
    around do |example|
      policy = Rails.application.config.content_security_policy
      policy.report_uri "https://sentry.example/api/1/security/?sentry_key=abc"
      example.run
    ensure
      policy.directives.delete("report-uri")
    end

    it "asks browsers to send reports from ordinary pages" do
      get about_path
      expect(report_only).to include("report-uri https://sentry.example/")
    end

    it "does not ask for reports from the unsubscribe page, whose address holds a token" do
      get unsubscribe_path(create(:confirmed_user).unsubscribe_token)
      expect(report_only).to be_present
      expect(report_only).not_to include("report-uri")
    end

    it "does not ask for reports from the password reset page, whose address holds a token" do
      get edit_user_password_path(reset_password_token: "not-a-real-token")
      expect(response).to have_http_status(:ok)
      expect(report_only).to be_present
      expect(report_only).not_to include("report-uri")
    end

    it "does not ask for reports from a confirmation page, whose address holds a token" do
      get user_confirmation_path(confirmation_token: "not-a-real-token")
      expect(report_only).to be_present
      expect(report_only).not_to include("report-uri")
    end
  end

  # A report from the next page includes its referrer, which would be the address with the token
  context "when a page's address holds a token" do
    it "sends no referrer from the unsubscribe page" do
      get unsubscribe_path(create(:confirmed_user).unsubscribe_token)
      expect(response.headers["Referrer-Policy"]).to eq "no-referrer"
    end

    it "sends no referrer from the password reset page" do
      get edit_user_password_path(reset_password_token: "not-a-real-token")
      expect(response.headers["Referrer-Policy"]).to eq "no-referrer"
    end

    it "sends no referrer from a confirmation page" do
      get user_confirmation_path(confirmation_token: "not-a-real-token")
      expect(response.headers["Referrer-Policy"]).to eq "no-referrer"
    end

    it "leaves the browser's default referrer policy on ordinary pages" do
      get about_path
      expect(response.headers["Referrer-Policy"]).not_to eq "no-referrer"
    end
  end

  context "when a card page is rendered" do
    let(:policy) { create(:policy) }

    it "gives its inline script the nonce from the header" do
      get policy_path(policy, card: 1)
      expect(response).to have_http_status(:ok)
      expect(inline_scripts).not_to be_empty
      expect(inline_scripts.pluck("nonce").uniq).to eq [nonce]
    end
  end
end

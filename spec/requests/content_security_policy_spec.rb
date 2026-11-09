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

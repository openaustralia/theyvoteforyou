# frozen_string_literal: true

require "spec_helper"

describe "application/_sentry_javascript", type: :view do
  context "when a sentry dsn is configured" do
    before do
      allow(Rails.application.credentials).to receive(:dig)
        .with(:sentry, :dsn)
        .and_return("https://examplepublickey@o0.ingest.sentry.io/0")
      allow(view).to receive(:user_signed_in?).and_return(false)
      render
    end

    it "defines the configuration before the loader script so a blocked loader can't raise ReferenceError" do
      expect(rendered.index("window.sentryOnLoad")).to be < rendered.index("js-de.sentry-cdn.com")
    end

    it "ignores errors injected by in-app browsers" do
      expect(rendered).to include("_AutofillCallbackHandler")
    end
  end

  context "when no sentry dsn is configured" do
    it "renders nothing" do
      allow(Rails.application.credentials).to receive(:dig)
        .with(:sentry, :dsn)
        .and_return(nil)
      render
      expect(rendered).to be_blank
    end
  end
end

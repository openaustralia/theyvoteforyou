# frozen_string_literal: true

require "spec_helper"

describe "application/_sentry_javascript", type: :view do
  let(:dsn) { Sentry::DSN.new("https://examplepublickey@o0.ingest.sentry.io/0") }

  context "when a sentry dsn is configured" do
    before do
      allow(Sentry).to receive(:initialized?).and_return(true)
      allow(Sentry.configuration).to receive(:dsn).and_return(dsn)
      allow(view).to receive(:user_signed_in?).and_return(false)
    end

    it "defines the configuration before the loader script so a blocked loader can't raise ReferenceError" do
      render
      expect(rendered.index("window.sentryOnLoad")).to be < rendered.index("js-de.sentry-cdn.com")
    end

    it "derives the loader script from the DSN public key" do
      render
      expect(rendered).to include("js-de.sentry-cdn.com/examplepublickey.min.js")
    end

    it "ignores errors injected by in-app browsers" do
      render
      expect(rendered).to include("_AutofillCallbackHandler")
    end

    it "renders nothing for crawlers" do
      controller.request.headers["User-Agent"] = "Mozilla/5.0 (compatible; Baiduspider/2.0)"
      render
      expect(rendered).to be_blank
    end

    context "when a user is signed in" do
      before do
        allow(view).to receive_messages(user_signed_in?: true, current_user: instance_double(User, id: 42))
        render
      end

      it "identifies the user by id alone" do
        expect(rendered).to include("Sentry.setUser({ id: '42' })")
      end

      it "sends no email address" do
        expect(rendered).not_to include("email:")
      end
    end
  end

  context "when no sentry dsn is configured" do
    it "renders nothing" do
      allow(Sentry.configuration).to receive(:dsn).and_return(nil)
      render
      expect(rendered).to be_blank
    end
  end
end

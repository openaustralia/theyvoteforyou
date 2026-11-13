# frozen_string_literal: true

require "spec_helper"

describe Sentry::Configuration, "#before_send" do
  subject(:scrubbed_event) { Sentry.configuration.before_send.call(event, {}) }

  let(:event) { Sentry::ErrorEvent.new(configuration: Sentry.configuration) }
  let(:breadcrumbs) { Sentry::BreadcrumbBuffer.new(5) }
  let(:crumb) { scrubbed_event.breadcrumbs.members.first }

  before { event.breadcrumbs = breadcrumbs }

  context "when a breadcrumb mentions an email address" do
    before do
      breadcrumbs.record(
        Sentry::Breadcrumb.new(message: "Sent to jane@example.com", data: { to: "jane@example.com" })
      )
    end

    it "filters the email address from the message" do
      expect(crumb.message).to eq("Sent to [FILTERED]")
    end

    it "filters the email address from the data" do
      expect(crumb.data).to eq(to: "[FILTERED]")
    end

    it "does not raise while the buffer still has empty slots" do
      expect { scrubbed_event }.not_to raise_error
    end
  end

  context "when there are no breadcrumbs" do
    it "returns the event" do
      expect(scrubbed_event).to eq(event)
    end
  end
end

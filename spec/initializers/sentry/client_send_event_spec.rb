# frozen_string_literal: true

require "spec_helper"

# Reproduces the production log line "Event sending failed: undefined method
# 'message' for nil", which came from the app's before_send hook meeting the
# nil slots of a breadcrumb buffer that isn't full yet.
describe Sentry::Client, "#send_event" do
  subject(:capture) { hub.capture_exception(StandardError.new("boom")) }

  let(:log) { StringIO.new }
  let(:configuration) do
    Sentry::Configuration.new.tap do |config|
      config.dsn = "http://key@sentry.example.com/1"
      config.sdk_logger = Logger.new(log)
      config.transport.transport_class = Sentry::DummyTransport
      # Send in the calling thread so the specs see the result
      config.background_worker_threads = 0
      config.before_send = Sentry.configuration.before_send
    end
  end
  let(:client) { described_class.new(configuration) }
  let(:hub) { Sentry::Hub.new(client, Sentry::Scope.new(max_breadcrumbs: 100)) }
  let(:sent_event) { client.transport.events.first }

  context "when the breadcrumb buffer is only partly full" do
    before do
      hub.add_breadcrumb(Sentry::Breadcrumb.new(message: "Sent to jane@example.com"))
      capture
    end

    it "sends the event" do
      expect(sent_event).to be_a(Sentry::ErrorEvent)
    end

    it "does not log a sending failure" do
      expect(log.string).not_to include("Event sending failed")
    end

    it "filters email addresses from the breadcrumbs" do
      expect(sent_event.breadcrumbs.members.first.message).to eq("Sent to [FILTERED]")
    end
  end

  context "when there are no breadcrumbs" do
    before { capture }

    it "sends the event" do
      expect(sent_event).to be_a(Sentry::ErrorEvent)
    end

    it "does not log a sending failure" do
      expect(log.string).not_to include("Event sending failed")
    end
  end
end

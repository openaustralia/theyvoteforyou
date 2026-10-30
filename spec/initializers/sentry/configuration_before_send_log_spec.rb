# frozen_string_literal: true

require "spec_helper"

describe Sentry::Configuration, "#before_send_log" do
  subject(:scrubbed_log) { Sentry.configuration.before_send_log.call(log) }

  let(:log) do
    Sentry::LogEvent.new(
      configuration: Sentry.configuration,
      level: :info,
      body: "Sent to jane@example.com",
      attributes: { to: "jane@example.com", count: 2 }
    )
  end

  it "filters the email address from the body" do
    expect(scrubbed_log.body).to eq("Sent to [FILTERED]")
  end

  it "filters the email address from the attributes" do
    expect(scrubbed_log.attributes).to eq(to: "[FILTERED]", count: 2)
  end
end

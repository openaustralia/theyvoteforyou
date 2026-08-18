# frozen_string_literal: true

require "spec_helper"

describe CardScreenshotter::Utils do
  subject(:screenshotter) { described_class.new }

  let(:driver) { instance_double(Selenium::WebDriver::Driver) }

  before do
    allow(Selenium::WebDriver).to receive(:for).and_return(driver)
    allow(driver).to receive(:execute_script).and_return(
      [described_class::CARD_WIDTH, described_class::CARD_HEIGHT, described_class::CARD_WIDTH,
       described_class::CARD_HEIGHT]
    )
    allow(driver).to receive(:quit)
  end

  describe "#screenshot" do
    it "wraps errors in ScreenshotError, keeping the url in the message and the original error as the cause" do
      allow(driver).to receive(:get).and_raise(Net::ReadTimeout)

      expect { screenshotter.screenshot("https://example.com/foo?card=true") }.to raise_error(
        CardScreenshotter::ScreenshotError, %r{https://example\.com/foo\?card=true}
      ) do |error|
        expect(error.cause).to be_a(Net::ReadTimeout)
      end
    end
  end

  describe "#screenshot_and_save" do
    let(:path) { Rails.root.join("tmp/test_cards/example.png").to_s }

    after { FileUtils.rm_rf(Rails.root.join("tmp/test_cards")) }

    it "saves the screenshot" do
      allow(driver).to receive(:get)
      allow(driver).to receive(:screenshot_as).with(:png).and_return("png data")

      screenshotter.screenshot_and_save("https://example.com", path)

      expect(File.read(path)).to eq "png data"
    end

    it "retries with a fresh browser after a transient failure" do
      attempts = 0
      allow(driver).to receive(:get) do
        attempts += 1
        raise Net::ReadTimeout if attempts == 1
      end
      allow(driver).to receive(:screenshot_as).with(:png).and_return("png data")

      screenshotter.screenshot_and_save("https://example.com", path)

      # The browser is restarted between attempts to clear any wedged state
      expect(driver).to have_received(:quit).once
      expect(File.read(path)).to eq "png data"
    end

    it "reports to Sentry and skips the url once retries are exhausted so the batch can continue" do
      allow(driver).to receive(:get).and_raise(Net::ReadTimeout)
      allow(Sentry).to receive(:initialized?).and_return(true)
      allow(Sentry).to receive(:capture_exception)

      expect { screenshotter.screenshot_and_save("https://example.com", path) }.not_to raise_error

      expect(Sentry).to have_received(:capture_exception).with(instance_of(CardScreenshotter::ScreenshotError))
      expect(File.exist?(path)).to be false
    end
  end
end

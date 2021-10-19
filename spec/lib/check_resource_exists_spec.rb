# frozen_string_literal: true

require "spec_helper"

describe CheckResourceExists do
  describe "#call" do
    context "when given a URL that returns a 200" do
      before { stub_request(:any, "example.com/foo/bar.img") }

      it { expect(described_class.call("http://example.com/foo/bar.img")).to be_truthy }
    end

    context "when given a URL that returns a 500" do
      before { stub_request(:any, "example.com/foo/bar.img").to_return(status: [500, "Internal Server Error"]) }

      it { expect(described_class.call("http://example.com/foo/bar.img")).to be_falsey }
    end

    context "when given a URL that returns a 404" do
      before { stub_request(:any, "example.com/foo/bar.img").to_return(status: [404, "Not Found"]) }

      it { expect(described_class.call("http://example.com/foo/bar.img")).to be_falsey }
    end
  end
end

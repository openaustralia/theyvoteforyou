# frozen_string_literal: true

require "spec_helper"

describe PortraitMirror do
  let(:root) { Rails.root.join("tmp/test_portraits") }
  let(:path) { root.join("large/10001.jpg") }
  let(:source) { "https://www.openaustralia.org.au/images/mpsL/10001.jpg" }

  after { FileUtils.rm_rf(root) }

  describe "#mirror" do
    subject(:mirror) { described_class.new(source, path).mirror }

    context "when the source returns an image" do
      before do
        stub_request(:get, source).to_return(status: 200, body: "jpeg bytes", headers: { "Content-Type" => "image/jpeg" })
      end

      it "writes the portrait" do
        mirror
        expect(File.binread(path)).to eq "jpeg bytes"
      end
    end

    it "gives up on a host that does not answer rather than waiting on Net::HTTP defaults" do
      stub_request(:get, source).to_return(status: 200, body: "png", headers: { "Content-Type" => "image/png" })
      allow(Net::HTTP).to receive(:start).and_call_original

      mirror

      expect(Net::HTTP).to have_received(:start).with(
        anything, anything, hash_including(open_timeout: described_class::OPEN_TIMEOUT,
                                           read_timeout: described_class::READ_TIMEOUT)
      )
      expect(File.binread(path)).to eq "png"
    end

    context "when a portrait has already been mirrored" do
      before do
        FileUtils.mkdir_p(path.dirname)
        File.binwrite(path, "old jpeg")
      end

      it "asks only for changes since the existing file was written" do
        stub = stub_request(:get, source).with(headers: { "If-Modified-Since" => File.mtime(path).httpdate })
                                         .to_return(status: 304)
        mirror
        expect(stub).to have_been_requested
      end

      it "leaves the existing file alone on a 304" do
        stub_request(:get, source).to_return(status: 304)
        mirror
        expect(File.binread(path)).to eq "old jpeg"
      end

      it "keeps the existing file when the source refuses the request" do
        stub_request(:get, source).to_return(status: 403, body: "<html>Just a moment...</html>")
        mirror
        expect(File.binread(path)).to eq "old jpeg"
      end

      it "keeps the existing file when the source is unreachable" do
        stub_request(:get, source).to_timeout
        expect { mirror }.not_to raise_error
        expect(File.binread(path)).to eq "old jpeg"
      end

      it "keeps the existing file when a 200 carries something other than an image" do
        stub_request(:get, source).to_return(status: 200, body: "<html>Just a moment...</html>",
                                             headers: { "Content-Type" => "text/html; charset=UTF-8" })
        mirror
        expect(File.binread(path)).to eq "old jpeg"
      end
    end

    context "when the source fails and nothing has been mirrored yet" do
      before { stub_request(:get, source).to_return(status: 404) }

      it "does not write anything" do
        mirror
        expect(File.exist?(path)).to be false
      end
    end
  end

  describe ".mirror" do
    let(:person) do
      create(:person, small_image_url: "https://example.com/small.jpg", large_image_url: nil,
                      extra_large_image_url: "https://example.com/xl.jpg")
    end

    before do
      stub_const("PortraitMirror::ROOT", root)
      stub_request(:get, "https://example.com/small.jpg").to_return(status: 200, body: "small", headers: { "Content-Type" => "image/jpeg" })
      stub_request(:get, "https://example.com/xl.jpg").to_return(status: 200, body: "xl", headers: { "Content-Type" => "image/jpeg" })
    end

    it "mirrors each size the person has a source for" do
      described_class.mirror(person)
      expect(File.binread(root.join("small/#{person.id}.jpg"))).to eq "small"
      expect(File.binread(root.join("extra_large/#{person.id}.jpg"))).to eq "xl"
      expect(File.exist?(root.join("large/#{person.id}.jpg"))).to be false
    end
  end

  describe ".run" do
    before { stub_const("PortraitMirror::ROOT", root) }

    it "mirrors every person, carrying on past failures" do
      failing = create(:person, small_image_url: "https://example.com/fails.jpg")
      working = create(:person, small_image_url: "https://example.com/works.jpg")
      stub_request(:get, "https://example.com/fails.jpg").to_return(status: 500)
      stub_request(:get, "https://example.com/works.jpg").to_return(status: 200, body: "works", headers: { "Content-Type" => "image/jpeg" })

      described_class.run

      expect(File.exist?(root.join("small/#{failing.id}.jpg"))).to be false
      expect(File.binread(root.join("small/#{working.id}.jpg"))).to eq "works"
    end
  end
end

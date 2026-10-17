# frozen_string_literal: true

require "spec_helper"

describe LocalHansardCache do
  let(:dir) { Rails.root.join("tmp/test_hansard_xml") }
  let(:cache) { described_class.new(dir: dir) }
  let(:scrapedxml) { %r{data\.openaustralia\.org\.au/scrapedxml/} }
  let(:sitting) { Date.new(2026, 8, 19) }
  let(:xml) do
    <<~XML
      <debates>
        <major-heading id="h1" url="x">BILLS</major-heading>
        <minor-heading id="h3" url="x">Example Bill 2026</minor-heading>
        <speech id="s1" speakername="Robin Carrow" time="10:00:00" url="x"><p>This change protects small business.</p></speech>
        <division divdate="2026-08-19" divnumber="1" id="d1" time="10:06:00" url="x"><divisioncount ayes="40" noes="30" pairs="0" tellerayes="0" tellernoes="0"/></division>
        <division divdate="2026-08-19" divnumber="2" id="d2" time="10:07:00" url="x"><divisioncount ayes="40" noes="30" pairs="0" tellerayes="0" tellernoes="0"/></division>
      </debates>
    XML
  end

  after { FileUtils.rm_rf(dir) }

  describe "#raw" do
    it "fetches a day once and reads it back from the folder" do
      stub_request(:get, scrapedxml).to_return(body: xml)

      expect(cache.raw("representatives", sitting)).to include("<division")
      expect(a_request(:get, scrapedxml)).to have_been_made.once
      expect(dir.join("representatives-2026-08-19.xml")).to exist
    end

    it "leaves no part of a day behind when a run stops part way through writing it" do
      stub_request(:get, scrapedxml).to_return(body: xml)
      allow(File).to receive(:write).and_wrap_original do |write, path, text|
        write.call(path, text[0, 50])
        raise Interrupt
      end

      expect { cache.raw("representatives", sitting) }.to raise_error(Interrupt)
      expect(dir.join("representatives-2026-08-19.xml")).not_to exist
    end

    it "remembers a day with no XML, so it isn't asked for again" do
      stub_request(:get, scrapedxml).to_return(status: 404)

      expect(cache.raw("senate", sitting)).to be_nil
      expect(cache.raw("senate", sitting)).to be_nil
      expect(a_request(:get, scrapedxml)).to have_been_made.once
      expect(dir.join("senate-2026-08-19.missing")).to exist
    end

    it "asks again for a recent day with no XML, since its Hansard may be published later" do
      stub_request(:get, scrapedxml).to_return(status: 404)
      recent = Date.current - 1

      expect(cache.raw("senate", recent)).to be_nil
      expect(cache.raw("senate", recent)).to be_nil
      expect(a_request(:get, scrapedxml)).to have_been_made.twice
      expect(dir.join("senate-#{recent}.missing")).not_to exist
    end
  end

  describe "#division_count" do
    it "counts the day's divisions, not the divisioncount inside one" do
      stub_request(:get, scrapedxml).to_return(body: xml)
      stub_request(:get, %r{scrapedxml/senate_debates/}).to_return(status: 404)

      expect(cache.division_count("representatives", sitting)).to eq 2
      expect(cache.division_count("senate", sitting)).to be_zero
    end
  end

  describe "#fetcher" do
    let(:fetch) { cache.fetcher }

    before { stub_request(:get, scrapedxml).to_return(body: xml) }

    it "parses each day once" do
      expect(fetch.call("representatives", sitting)).to equal fetch.call("representatives", sitting)
    end

    it "lets go of the day it read longest ago once it holds as many days as the earlier-debate lookup reaches" do
      first = fetch.call("representatives", sitting)
      described_class::PARSED_DAYS_KEPT.times { |offset| fetch.call("representatives", sitting - offset - 1) }

      again = fetch.call("representatives", sitting)
      expect(again).not_to equal first
      expect(again.to_xml).to eq first.to_xml
    end
  end

  describe "#divisions?" do
    it "says a house voted when its XML holds a division" do
      stub_request(:get, scrapedxml).to_return(body: xml)
      stub_request(:get, %r{scrapedxml/senate_debates/}).to_return(status: 404)

      expect(cache.divisions?("representatives", sitting)).to be true
      expect(cache.divisions?("senate", sitting)).to be false
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

describe DivisionSummaryPipeline::HansardStore do
  subject(:store) { described_class.new(dir: dir) }

  let(:dir) { Pathname(Dir.mktmpdir) }
  let(:url) { "http://data.openaustralia.org.au/scrapedxml/senate_debates/2026-09-17.xml" }
  let(:published) { %(<?xml version="1.0" encoding="UTF-8"?>\n<debates proof="1">\n  <speech id="a"/>\n</debates>\n) }

  after { FileUtils.rm_rf(dir) }

  it "reads a day it already has, without downloading it" do
    dir.join("senate-2026-09-17.xml").write(published)

    expect(store.raw("senate", Date.new(2026, 9, 17))).to eq(published)
    expect(a_request(:get, url)).not_to have_been_made
  end

  it "downloads a day it doesn't have, and keeps it exactly as published" do
    stub_request(:get, url).to_return(body: published, headers: { "Content-Type" => "text/xml" })

    expect(store.raw("senate", Date.new(2026, 9, 17))).to eq(published)
    expect(dir.join("senate-2026-09-17.xml").read).to eq(published)
    expect(dir.children.map { |file| file.basename.to_s }).to eq(["senate-2026-09-17.xml"])
  end

  it "doesn't remember a recent day as having no Hansard, so it asks again next time" do
    recent = Date.current - 3
    missing = stub_request(:get, "http://data.openaustralia.org.au/scrapedxml/senate_debates/#{recent}.xml")
              .to_return(status: 404)

    2.times { expect(store.raw("senate", recent)).to be_nil }
    expect(missing).to have_been_requested.twice
  end

  it "notes a day it couldn't download, and keeps nothing for it" do
    stub_request(:get, url).to_raise(SocketError)

    expect { store.raw("senate", Date.new(2026, 9, 17)) }
      .to raise_error(described_class::DownloadFailed, /senate 2026-09-17 \(SocketError/)
    expect(store.failures).to eq(["senate/2026-09-17 (SocketError: Exception from WebMock)"])
    expect(dir.children).to be_empty
  end

  it "remembers a day with no Hansard, and doesn't ask for it again" do
    missing = stub_request(:get, url).to_return(status: 404)

    2.times { expect(store.raw("senate", Date.new(2026, 9, 17))).to be_nil }
    expect(missing).to have_been_requested.once
  end

  it "asks again about a day remembered as having no Hansard, when told to" do
    FileUtils.touch(dir.join("senate-2026-09-17.missing"))
    stub_request(:get, url).to_return(body: published, headers: { "Content-Type" => "text/xml" })

    expect(store.raw("senate", Date.new(2026, 9, 17))).to be_nil
    expect(store.raw("senate", Date.new(2026, 9, 17), recheck_missing: true)).to eq(published)
    expect(dir.join("senate-2026-09-17.missing")).not_to exist
  end

  it "describes a day by its version and a fingerprint of the whole file" do
    dir.join("senate-2026-09-17.xml").write(published)

    expect(store.describe("senate", Date.new(2026, 9, 17)))
      .to eq("version" => "proof", "fingerprint" => Digest::SHA256.hexdigest(published)[0, 16])
  end

  it "calls a day final when the parser marks it so, and unknown when it isn't marked" do
    dir.join("senate-2026-09-17.xml").write(published.sub('proof="1"', 'proof="0"'))
    dir.join("senate-2026-09-18.xml").write(published.sub(' proof="1"', ""))

    expect(store.describe("senate", Date.new(2026, 9, 17))["version"]).to eq("final")
    expect(store.describe("senate", Date.new(2026, 9, 18))["version"]).to eq("unknown")
  end

  it "hands ContextBuilder a parsed document for an earlier day" do
    dir.join("senate-2026-09-17.xml").write(published)

    expect(store.fetcher.call("senate", Date.new(2026, 9, 17)).at("speech")[:id]).to eq("a")
  end
end

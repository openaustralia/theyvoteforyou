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
  end

  it "remembers a day with no Hansard, and doesn't ask for it again" do
    missing = stub_request(:get, url).to_return(status: 404)

    2.times { expect(store.raw("senate", Date.new(2026, 9, 17))).to be_nil }
    expect(missing).to have_been_requested.once
  end

  it "hands ContextBuilder a parsed document for an earlier day" do
    dir.join("senate-2026-09-17.xml").write(published)

    expect(store.fetcher.call("senate", Date.new(2026, 9, 17)).at("speech")[:id]).to eq("a")
  end
end

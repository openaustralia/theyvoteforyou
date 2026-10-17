# frozen_string_literal: true

require "spec_helper"

describe LocalDraftRun do
  let(:root) { Rails.root.join("tmp/test_local_runs") }
  let(:hansard_dir) { Rails.root.join("tmp/test_hansard_xml") }
  let(:replies_dir) { Rails.root.join("tmp/test_llm_replies") }
  let(:completions) { "http://model.test:8080/v1/chat/completions" }
  let(:client) { LocalModelClient.new(url: "http://model.test:8080", model: "Example-Model-Q4", replies_dir: replies_dir) }
  let(:out) { StringIO.new }
  let(:loaded) { [] }
  let(:loader) { ->(date) { loaded << date } }
  let(:day) { Date.new(2026, 8, 19) }
  let(:model_folder) { root.join("local.Example-Model-Q4") }
  let(:draft_path) { model_folder.join("representatives/2026-08-19/representatives_2026-08-19_1.md") }
  let(:failed_path) { root.join("failed/local.Example-Model-Q4/representatives_2026-08-19_1.md") }

  # The same fictional sitting day as DivisionSummarizer's spec, so a reply pointing at S1.1 resolves.
  let(:xml) do
    <<~XML
      <debates>
        <major-heading id="h1" url="x">BILLS</major-heading>
        <minor-heading id="h3" url="x">Example Bill 2026</minor-heading>
        <speech id="s1" speakername="Robin Carrow" time="10:00:00" url="x"><p>This change protects small business.</p><p>I move:</p><p class="italic">That the words "the Minister" be omitted.</p></speech>
        <speech id="s2" speakername="Casey Whitlow" time="10:05:00" url="x"><p>The question is that the amendment be agreed to.</p></speech>
        <division divdate="2026-08-19" divnumber="1" id="d1" time="10:06:00" url="x"><divisioncount ayes="40" noes="30" pairs="0" tellerayes="0" tellernoes="0"/></division>
      </debates>
    XML
  end
  let(:good_reply) { { interpretation: { template_id: 4, missing: [] }, references: { explanation: ["S1.1"], motion: [] } }.to_json }

  def run_with(**)
    described_class.new(client: client, houses: ["representatives"], root: root, out: out, loader: loader,
                        cache: LocalHansardCache.new(dir: hansard_dir), **)
  end

  def model_replies_with(content)
    stub_request(:post, completions)
      .to_return(body: { choices: [{ message: { content: content }, finish_reason: "stop" }] }.to_json)
  end

  before do
    FileUtils.mkdir_p(hansard_dir)
    File.write(hansard_dir.join("representatives-2026-08-19.xml"), xml)
    # Any other day has no Hansard, as on a day parliament didn't sit.
    stub_request(:get, %r{data\.openaustralia\.org\.au/scrapedxml/}).to_return(status: 404)
    model_replies_with(good_reply)
  end

  after { [root, hansard_dir, replies_dir].each { |dir| FileUtils.rm_rf(dir) } }

  describe "#run" do
    before { create(:division, house: "representatives", date: day, number: 1) }

    it "writes each division's draft into the model's folder, named after the division's URL" do
      run_with.run(from: day, to: day)

      expect(File.read(draft_path)).to start_with("# ").and include(
        "## Reviewer Only", "| Division URL | https://theyvoteforyou.org.au/divisions/representatives/2026-08-19/1 |"
      )
      expect(out.string).to include "representatives/2026-08-19/1: drafted in"
    end

    it "skips a division that already has a draft, so a stopped run carries on where it left off" do
      run_with.run(from: day, to: day)
      second = run_with
      second.run(from: day, to: day)

      expect(a_request(:post, completions)).to have_been_made.once
      expect(second.counts[:skipped]).to eq 1
    end

    it "drafts it again when forced" do
      run_with.run(from: day, to: day)
      run_with(force: true).run(from: day, to: day)

      expect(a_request(:post, completions)).to have_been_made.twice
    end

    it "keeps a failed draft out of the model's folder, and tries it again only when asked" do
      model_replies_with("not JSON")
      run_with.run(from: day, to: day)
      expect([failed_path.exist?, draft_path.exist?]).to eq [true, false]

      run_with.run(from: day, to: day)
      expect(a_request(:post, completions)).to have_been_made.once

      model_replies_with(good_reply)
      run_with(retry_failed: true).run(from: day, to: day)
      expect([failed_path.exist?, draft_path.exist?]).to eq [false, true]
    end

    it "goes newest first: by date, then by number within a day" do
      create(:division, house: "representatives", date: day, number: 2)
      create(:division, house: "representatives", date: day - 1, number: 1)
      run_with.run(from: day - 1, to: day)

      slugs = out.string.scan(%r{^(representatives/\S+):}).flatten
      expect(slugs).to eq %w[representatives/2026-08-19/2 representatives/2026-08-19/1 representatives/2026-08-18/1]
    end

    it "only drafts the houses asked for" do
      create(:division, house: "senate", date: day, number: 1)
      run_with.run(from: day, to: day)

      expect(out.string).not_to include "senate/"
    end

    it "stops without writing anything when the model server goes away" do
      stub_request(:post, completions).to_raise(Errno::ECONNREFUSED)

      expect { run_with.run(from: day, to: day) }.to raise_error(LocalModelClient::Unreachable)
      expect(Dir.exist?(root)).to be false
    end

    it "refuses a range whose start is after its end, rather than quietly drafting nothing" do
      expect { run_with.run(from: day + 1, to: day) }.to raise_error(described_class::EmptyRange, /FROM/)
    end
  end

  describe "loading sitting days" do
    it "loads a day the database doesn't have yet, only when Hansard shows a vote that day" do
      loader = lambda do |date|
        loaded << date
        create(:division, house: "representatives", date: date, number: 1)
      end
      run_with(loader: loader).run(from: day - 1, to: day + 1)

      expect(loaded).to eq [day]
      expect(draft_path).to exist
    end

    it "skips a day it can't load, says so, and carries on" do
      run = run_with(loader: ->(_date) { raise "Couldn't find member by gid 123" })
      run.run(from: day, to: day)

      expect(out.string).to include "representatives/2026-08-19: couldn't load this day's divisions"
      expect(run.counts[:days_not_loaded]).to eq 1
    end

    it "loads the rest of a day a stopped run left half-loaded, and drafts the divisions left over" do
      two_divisions = <<~XML
        <debates>
          <major-heading id="h1" url="x">BILLS</major-heading>
          <minor-heading id="h3" url="x">Example Bill 2026</minor-heading>
          <speech id="s1" speakername="Robin Carrow" time="10:00:00" url="x"><p>This change protects small business.</p><p>I move:</p><p class="italic">That the words "the Minister" be omitted.</p></speech>
          <speech id="s2" speakername="Casey Whitlow" time="10:05:00" url="x"><p>The question is that the amendment be agreed to.</p></speech>
          <division divdate="2026-08-19" divnumber="1" id="d1" time="10:06:00" url="x"><divisioncount ayes="40" noes="30" pairs="0" tellerayes="0" tellernoes="0"/></division>
          <division divdate="2026-08-19" divnumber="2" id="d2" time="10:07:00" url="x"><divisioncount ayes="40" noes="30" pairs="0" tellerayes="0" tellernoes="0"/></division>
        </debates>
      XML
      File.write(hansard_dir.join("representatives-2026-08-19.xml"), two_divisions)
      create(:division, house: "representatives", date: day, number: 1)
      loader = lambda do |date|
        create(:division, house: "representatives", date: date, number: 2)
      end

      run = run_with(loader: loader)
      run.run(from: day, to: day)

      expect(a_request(:post, completions)).to have_been_made.twice
      expect(run.counts[:drafted] + run.counts[:failed]).to eq 2
      expect(run.counts[:skipped]).to be_zero
    end
  end

  describe "#run_one" do
    before { create(:division, house: "representatives", date: day, number: 1) }

    it "drafts the one division a URL names" do
      run_with.run_one("https://theyvoteforyou.org.au/divisions/representatives/2026-08-19/1")

      expect(draft_path).to exist
    end

    it "says so when the division already has a file" do
      run_with.run_one("representatives/2026-08-19/1")
      run_with.run_one("representatives/2026-08-19/1")

      expect(out.string).to include "representatives/2026-08-19/1: skipped, as it already has a file"
    end

    it "refuses something that isn't a division" do
      expect { run_with.run_one("representatives/2026-08-19") }.to raise_error(described_class::UnknownDivision, /doesn't name a division/)
    end
  end

  describe ".parse_slug" do
    it "reads a slug or a whole division URL" do
      expect(described_class.parse_slug("senate/2026-09-17/8")).to eq ["senate", Date.new(2026, 9, 17), 8]
      expect(described_class.parse_slug("https://theyvoteforyou.org.au/divisions/representatives/2026-09-17/3/"))
        .to eq ["representatives", Date.new(2026, 9, 17), 3]
    end

    it "names nothing for anything else" do
      expect(described_class.parse_slug("commons/2026-09-17/3")).to be_nil
      expect(described_class.parse_slug("senate/2026-02-30/1")).to be_nil
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

describe DivisionSummaryPipeline::RouteSnapshot do
  subject(:snapshot) { described_class.new(folder: folder, store: DivisionSummaryPipeline::HansardStore.new(dir: hansard)) }

  let(:folder) { Pathname(Dir.mktmpdir) }
  let(:hansard) { Pathname(Dir.mktmpdir) }

  let(:settings) do
    <<~YAML
      range:
        from: 2025-01-01
        to: 2026-10-31
      parliaments:
        47: 2022-07-26
        48: 2025-07-22
    YAML
  end

  before { folder.join("settings.yml").write(settings) }

  after { FileUtils.rm_rf([folder, hansard]) }

  describe "#years" do
    it "is every year the range touches, when none is named" do
      expect(snapshot.years).to eq([2025, 2026])
    end

    it "takes one year, or a range of years" do
      expect(snapshot.years("2026")).to eq([2026])
      expect(snapshot.years("2025-2026")).to eq([2025, 2026])
    end

    it "refuses a year outside the range, saying how to include it" do
      expect { snapshot.years("2024") }.to raise_error(
        described_class::Refused,
        "2024 is outside the range in settings.yml (2025-01-01 to 2026-10-31). " \
        "To include it, change the range there first, then run again."
      )
    end

    it "refuses anything that isn't a year or a range of years, including one written backwards" do
      expect { snapshot.years("last year") }.to raise_error(described_class::Refused, /must be a year/)
      expect { snapshot.years("2026-2025") }.to raise_error(described_class::Refused, /no years in it/)
    end
  end

  describe "#parliament" do
    it "is the latest Parliament in settings.yml to begin on or before the date" do
      expect(snapshot.parliament(Date.new(2025, 3, 27))).to eq(47)
      expect(snapshot.parliament(Date.new(2025, 7, 22))).to eq(48)
    end

    it "refuses a range that starts before the first Parliament listed" do
      folder.join("settings.yml").write(settings.sub("47: 2022-07-26\n", ""))

      expect { snapshot }.to raise_error(described_class::Refused, /starts on 2025-01-01, before the first Parliament/)
    end
  end

  describe "#write" do
    # A closure (a vote to end the debate and vote now) that the House divided on, the same example as
    # in context_builder_spec.rb.
    let(:parlparse_xml) do
      <<~XML
        <debates>
          <major-heading id="d1" url="http://example.org/1">BILLS</major-heading>
          <minor-heading id="d2" url="http://example.org/1">Border Processing Amendment Bill 2026</minor-heading>
          <speech id="d3" speakerid="uk.org.publicwhip/member/1" speakername="Daniel Whitfield" time="10:10:00" url="http://example.org/1">
            <p>I move: That the question be now put.</p>
          </speech>
          <division divdate="2026-08-19" divnumber="1" id="d5" nospeaker="true" time="10:15:00" url="http://example.org/1">
            <divisioncount ayes="82" noes="54" pairs="0" tellerayes="0" tellernoes="0"/>
          </division>
        </debates>
      XML
    end

    before do
      hansard.join("representatives-2026-08-19.xml").write(parlparse_xml)
      create(:division, house: "representatives", date: Date.new(2026, 8, 19), number: 1)
      # After the range ends, so not in the 2026 file.
      create(:division, house: "representatives", date: Date.new(2026, 11, 2), number: 1)
    end

    it "writes an entry for each division in the year's part of the range, named by house, date and number" do
      expect(snapshot.write(2026)).to eq(divisions: 1, errors: 0, changed_hansard: [])

      written = YAML.safe_load(snapshot.path(2026).read)
      expect(written["divisions"].keys).to eq(["representatives_2026-08-19_1"])
      expect(written["divisions"]["representatives_2026-08-19_1"]["route"]["template"]).to eq(22)
    end

    it "records the Parliament, the version of the day's Hansard and the days Stage 1 read" do
      snapshot.write(2026)

      block = YAML.safe_load(snapshot.path(2026).read)["divisions"]["representatives_2026-08-19_1"]
      expect(block).to include("parliament" => 48, "hansard" => "unknown",
                               "hansard_read" => ["representatives/2026-08-19"])
    end

    it "lists every Hansard day read at the top, with its version and fingerprint" do
      snapshot.write(2026)

      expect(YAML.safe_load(snapshot.path(2026).read)["hansard_days"]).to eq(
        "representatives/2026-08-19" => { "version" => "unknown",
                                          "fingerprint" => Digest::SHA256.hexdigest(parlparse_xml)[0, 16] }
      )
    end

    it "says which days' Hansard has changed since the file was last written" do
      snapshot.write(2026)
      hansard.join("representatives-2026-08-19.xml").write(parlparse_xml.sub("<debates>", '<debates proof="0">'))
      again = described_class.new(folder: folder, store: DivisionSummaryPipeline::HansardStore.new(dir: hansard))

      expect(again.write(2026)[:changed_hansard]).to eq(["representatives/2026-08-19 (unknown, now final)"])
    end

    it "starts the file with a note saying how it was made" do
      snapshot.write(2026)

      expect(snapshot.path(2026).read).to start_with("# Routing snapshot for 2026:")
    end

    it "writes the same file when run again from scratch with nothing changed" do
      snapshot.write(2026)
      first = snapshot.path(2026).read
      again = described_class.new(folder: folder, store: DivisionSummaryPipeline::HansardStore.new(dir: hansard))

      expect(again.write(2026)[:changed_hansard]).to be_empty
      expect(again.path(2026).read).to eq(first)
    end

    it "records a division Stages 1 and 2 fail on as an error, with any memory address hidden, and carries on" do
      # Stage 1 doesn't fail on any real Hansard we have, so this test pretends it does.
      allow(DivisionSummaryPipeline::ContextBuilder).to receive(:build)
        .and_raise(ArgumentError, "bad packet at 0x00007f3a12bc")

      expect(snapshot.write(2026)).to include(divisions: 1, errors: 1)
      entry = YAML.safe_load(snapshot.path(2026).read)["divisions"]["representatives_2026-08-19_1"]
      expect(entry).to eq("error" => "ArgumentError: bad packet at 0x...")
    end

    context "when Stage 1 looks back to earlier sitting days" do
      # An amendment moved on 18 August and put to the vote without debate on 20 August, so Stage 1
      # looks back through 19 August (another debate) to 18 August to find it, as in
      # context_builder_spec.rb.
      let(:heading) do
        %(<major-heading id="h0" url="x">BILLS</major-heading>) +
          %(<minor-heading id="h1" url="x">Example Bill 2026; Second Reading</minor-heading>)
      end
      let(:earlier_day) do
        <<~XML
          <debates>
            #{heading}
            <speech id="s1" speakerid="uk.org.publicwhip/member/900301" speakername="Robin Carrow" time="12:33:00" url="x"><p>I rise to speak, and I move:</p><p class="italic">That all words after "That" be omitted with a view to substituting the following words: "whilst not declining to give the bill a second reading, the House notes the cost to small business".</p></speech>
          </debates>
        XML
      end
      let(:vote_day) do
        <<~XML
          <debates>
            #{heading}
            <speech id="s2" speakerid="uk.org.publicwhip/member/900202" speakername="Casey Whitlow" time="09:20:00" url="x"><p>In accordance with standing order 133, I shall now proceed to put the question on the amendment moved by the member for Exampleton.</p><p>The question is that the amendment be agreed to.</p></speech>
            <division divdate="2026-08-20" divnumber="1" id="d9" nospeaker="true" time="09:21:00" url="x">
              <divisioncount ayes="70" noes="60" pairs="0" tellerayes="0" tellernoes="0"/>
            </division>
          </debates>
        XML
      end
      let(:earlier_url) { "http://data.openaustralia.org.au/scrapedxml/representatives_debates/2026-08-18.xml" }

      before do
        hansard.join("representatives-2026-08-20.xml").write(vote_day)
        create(:division, house: "representatives", date: Date.new(2026, 8, 20), number: 1)
        # Every other day it looks at has no Hansard.
        stub_request(:get, %r{scrapedxml/representatives_debates/}).to_return(status: 404)
      end

      it "records every earlier day it opened, in the entry and in the list at the top" do
        hansard.join("representatives-2026-08-18.xml").write(earlier_day)
        snapshot.write(2026)

        written = YAML.safe_load(snapshot.path(2026).read)
        days = %w[representatives/2026-08-18 representatives/2026-08-19 representatives/2026-08-20]
        expect(written["divisions"]["representatives_2026-08-20_1"]).to include("hansard_read" => days,
                                                                                "earlier_debate" => ["2026-08-18"])
        expect(written["hansard_days"].keys).to eq(days)
      end

      it "writes nothing when an earlier day couldn't be downloaded, and says which day" do
        stub_request(:get, earlier_url).to_raise(SocketError)

        expect { snapshot.write(2026) }
          .to raise_error(described_class::Refused, %r{representatives/2026-08-18 \(SocketError})
        expect(snapshot.path(2026)).not_to exist
      end
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

describe DivisionSummaryPipeline::RouteSnapshot do
  subject(:snapshot) { described_class.new(folder: folder, store: DivisionSummaryPipeline::HansardStore.new(dir: hansard)) }

  let(:folder) { Pathname(Dir.mktmpdir) }
  let(:hansard) { Pathname(Dir.mktmpdir) }

  before do
    folder.join("settings.yml").write(<<~YAML)
      range:
        from: 2025-01-01
        to: 2026-10-31
    YAML
  end

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

  describe "#write" do
    # A closure the House divided on, as in context_builder_spec.rb.
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

    it "writes a block for each division in the year's part of the range, keyed by house, date and number" do
      expect(snapshot.write(2026)).to eq(divisions: 1, errors: 0)

      written = YAML.safe_load(snapshot.path(2026).read)
      expect(written["divisions"].keys).to eq(["representatives_2026-08-19_1"])
      expect(written["divisions"]["representatives_2026-08-19_1"]["route"]["template"]).to eq(22)
    end

    it "starts the file with a note saying how it was made" do
      snapshot.write(2026)

      expect(snapshot.path(2026).read).to start_with("# Routing snapshot for 2026:")
    end

    it "writes the same file when run again with nothing changed" do
      snapshot.write(2026)
      first = snapshot.path(2026).read
      snapshot.write(2026)

      expect(snapshot.path(2026).read).to eq(first)
    end
  end
end

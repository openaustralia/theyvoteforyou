# frozen_string_literal: true

require "spec_helper"

# The loader has to leave each division with its caches already built, otherwise
# the division pages 500 for as long as it takes the separate cache rake task to
# catch up. See https://github.com/openaustralia/theyvoteforyou/issues/1641
describe DataLoader::Debates do
  describe ".load!" do
    subject(:load_divisions) { described_class.load!(date) }

    let(:date) { Date.new(2009, 11, 25) }
    let(:xml) { File.read(File.expand_path("../../fixtures/2009-11-25.xml", __dir__)) }

    def url_for(house)
      "#{Rails.configuration.xml_data_base_url}scrapedxml/#{house}_debates/#{date}.xml"
    end

    before do
      stub_request(:get, url_for("representatives")).to_return(body: xml, headers: { "Content-Type" => "text/xml" })
      stub_request(:get, url_for("senate")).to_return(status: 404)

      # Every member the XML votes reference has to exist or the loader raises.
      # Split them across two parties so the whip guesses are meaningful.
      xml.scan(%r{uk\.org\.publicwhip/member/(\d+)}).flatten.uniq.each_with_index do |id, i|
        Member.create!(gid: "uk.org.publicwhip/member/#{id}",
                       source_gid: "", title: "", first_name: "Member", last_name: id,
                       constituency: "", party: i.even? ? "Party A" : "Party B",
                       house: "representatives",
                       entered_house: Date.new(2000, 1, 1), left_house: Date.new(2020, 1, 1),
                       person: create(:person))
      end
    end

    it "loads the divisions" do
      load_divisions
      expect(Division.count).to eq(2)
    end

    it "builds a division_info for every division it loads" do
      load_divisions
      expect(Division.all).to all(satisfy { |d| d.division_info.present? })
    end

    it "builds whips for every division it loads" do
      load_divisions
      expect(Division.all).to all(satisfy { |d| d.whips.any? })
    end

    it "leaves every division with a known outcome" do
      load_divisions
      expect(Division.all.map(&:outcome_known?)).to all(be(true))
    end

    it "records a turnout matching the votes it loaded" do
      load_divisions
      division = Division.find_by(number: 1)
      expect(division.division_info.turnout).to eq(division.votes.count)
    end

    it "calculates the aye majority" do
      load_divisions
      division = Division.find_by(number: 1)
      ayes = division.votes.where(vote: "aye").count
      noes = division.votes.where(vote: "no").count
      expect(division.division_info.aye_majority).to eq(ayes - noes)
    end

    it "rebuilds the caches when the same division is loaded again" do
      load_divisions
      expect { described_class.load!(date) }.not_to change(DivisionInfo, :count)
    end

    # One agent for the whole run lets Mechanize reuse its connections between requests.
    it "fetches every house's XML with one Mechanize agent" do
      allow(Mechanize).to receive(:new).and_call_original
      load_divisions
      expect(Mechanize).to have_received(:new).once
    end
  end

  describe ".xml_url" do
    it "names the house's debates file for the day under the data source" do
      expect(described_class.xml_url("senate", Date.new(2009, 11, 25)))
        .to eq("#{Rails.configuration.xml_data_base_url}scrapedxml/senate_debates/2009-11-25.xml")
    end
  end

  describe ".fetch_xml_document" do
    subject(:fetch) { described_class.fetch_xml_document("senate", date) }

    let(:date) { Date.new(2009, 11, 25) }
    let(:url) { described_class.xml_url("senate", date) }

    context "when the source has the day's XML" do
      before { stub_request(:get, url).to_return(body: "<debates><speech/></debates>") }

      it "returns the parsed document" do
        expect(fetch.search("speech").size).to eq(1)
      end
    end

    context "when the source has no XML for the day" do
      before { stub_request(:get, url).to_return(status: 404) }

      it "returns nil" do
        expect(fetch).to be_nil
      end
    end

    context "when the source fails for any other reason" do
      before { stub_request(:get, url).to_return(status: 500) }

      it "raises the error rather than reading it as a missing day" do
        expect { fetch }.to raise_error(Mechanize::ResponseCodeError)
      end
    end

    context "with an agent passed in" do
      let(:agent) { Mechanize.new }

      before do
        stub_request(:get, url).to_return(body: "<debates/>")
        allow(agent).to receive(:get).and_call_original
      end

      it "makes the request with that agent" do
        described_class.fetch_xml_document("senate", date, agent: agent)
        expect(agent).to have_received(:get).with(url)
      end
    end
  end
end

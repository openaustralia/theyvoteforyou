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
  end
end

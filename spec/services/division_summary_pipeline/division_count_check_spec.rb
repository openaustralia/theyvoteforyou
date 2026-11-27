# frozen_string_literal: true

require "spec_helper"

describe DivisionSummaryPipeline::DivisionCountCheck do
  subject(:check) { described_class.new(DivisionSummaryPipeline::HansardStore.new(dir: hansard)) }

  let(:hansard) { Pathname(Dir.mktmpdir) }
  let(:day) { Date.new(2026, 8, 19) }
  let(:senate_url) { DataLoader::Debates.xml_url("senate", day) }

  # A day's Hansard recording this many divisions.
  def hansard_with(divisions)
    elements = (1..divisions).map { |number| %(<division divdate="2026-08-19" divnumber="#{number}"/>) }
    "<debates>#{elements.join}</debates>"
  end

  before do
    # The House didn't sit that day.
    stub_request(:get, %r{scrapedxml/representatives_debates/}).to_return(status: 404)
    create(:division, house: "senate", date: day, number: 1)
  end

  after { FileUtils.rm_rf(hansard) }

  it "passes when the database holds every division that Hansard records" do
    hansard.join("senate-2026-08-19.xml").write(hansard_with(1))

    expect { check.call([day]) }.not_to raise_error
  end

  it "stops when the database is missing some, saying which days and how to load them" do
    hansard.join("senate-2026-08-19.xml").write(hansard_with(3))

    expect { check.call([day]) }.to raise_error(
      DivisionSummaryPipeline::RouteSnapshot::Refused,
      /senate 2026-08-19: 2 missing.*application:load:divisions\[2026-08-19,2026-08-19\]/m
    )
  end

  it "asks again about a day remembered as having no Hansard when the database has divisions on it" do
    FileUtils.touch(hansard.join("senate-2026-08-19.missing"))
    stub_request(:get, senate_url).to_return(body: hansard_with(1), headers: { "Content-Type" => "text/xml" })

    expect { check.call([day]) }.not_to raise_error
    expect(hansard.join("senate-2026-08-19.xml")).to exist
  end
end

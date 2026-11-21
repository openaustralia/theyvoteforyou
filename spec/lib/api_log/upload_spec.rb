# frozen_string_literal: true

require "spec_helper"

# CI has no Elasticsearch, so its requests are stubbed and checked here
describe ApiLog::Upload do
  let(:out) { StringIO.new }
  let(:user) { create(:user) }
  let(:json) { { "Content-Type" => "application/json" } }
  let(:bulk_ok) { { status: 200, headers: json, body: { errors: false, items: [] }.to_json } }

  def row(created_at, query: "/api/v1/policies.json")
    ApiStatistic.create!(user: user, query: query, created_at: created_at)
  end

  def bulk_lines
    lines = []
    expect(a_request(:post, %r{/_bulk\z}).with { |request| lines.concat(request.body.split("\n").map { |l| JSON.parse(l) }) })
      .to have_been_made.at_least_once
    lines
  end

  before do
    stub_request(:head, /tvfy_api_test_\d{4}\z/).to_return(status: 404)
    stub_request(:put, /tvfy_api_test_\d{4}\.\d{2}\z/).to_return(status: 200, headers: json, body: "{}")
    stub_request(:post, %r{/_bulk\z}).to_return(bulk_ok)
  end

  it "sends each row to its month's index, under the same id the live job uses" do
    march = row(Time.utc(2024, 3, 31, 23, 59))
    april = row(Time.utc(2024, 4, 1))

    expect(described_class.run(from: "2024-03", to: "2024-04", out: out)).to be true

    actions = bulk_lines.each_slice(2).to_h { |action, _document| [action["index"]["_id"], action["index"]["_index"]] }
    expect(actions).to eq(
      "api_statistics-#{march.id}" => "tvfy_api_test_2024.03", "api_statistics-#{april.id}" => "tvfy_api_test_2024.04"
    )
    expect(a_request(:put, %r{/tvfy_api_test_2024\.03\z})).to have_been_made
  end

  it "leaves out a key still held in an older row's query" do
    row(Time.utc(2024, 3, 5), query: "/api/v1/policies.json?key=secret&format=json")

    described_class.month(Date.new(2024, 3, 1), out: out)

    expect(bulk_lines.last["query"]).to eq "/api/v1/policies.json?format=json"
  end

  it "sends the rest of the month when an old row's query can't be read, but returns false" do
    allow(Sentry).to receive(:capture_message)
    unreadable = row(Time.utc(2024, 3, 5), query: "/api/v1/people.json?%zz=1")
    readable = row(Time.utc(2024, 3, 6))

    expect(described_class.run(from: "2024-03", to: "2024-03", out: out)).to be false
    expect(bulk_lines.filter_map { |line| line.dig("index", "_id") }).to eq ["api_statistics-#{readable.id}"]
    expect(out.string).to include "sent 1 rows", "left out 1 rows", "api_statistics-#{unreadable.id}"
    expect(Sentry).to have_received(:capture_message).once
  end

  it "skips a month whose year has been combined into a yearly index" do
    stub_request(:head, %r{/tvfy_api_test_2024\z}).to_return(status: 200)
    row(Time.utc(2024, 3, 5))

    expect(described_class.month(Date.new(2024, 3, 1), out: out)).to be true
    expect(out.string).to include "2024 has been combined"
    expect(a_request(:post, %r{/_bulk\z})).not_to have_been_made
  end

  it "skips a month with no rows without asking Elasticsearch anything" do
    expect(described_class.month(Date.new(2024, 3, 1), out: out)).to be true
    expect(a_request(:any, /.*/)).not_to have_been_made
  end

  it "carries on with later months but returns false when Elasticsearch rejects rows" do
    stub_request(:post, %r{/_bulk\z}).to_return(
      { status: 200, headers: json, body: {
        errors: true,
        items: [{ index: { _id: "api_statistics-1", status: 400,
                           error: { type: "mapper_parsing_exception", reason: "failed to parse" } } }]
      }.to_json },
      bulk_ok
    )
    allow(Sentry).to receive(:capture_message)
    row(Time.utc(2024, 3, 5))
    row(Time.utc(2024, 4, 5))

    expect(described_class.run(from: "2024-03", to: "2024-04", out: out)).to be false
    expect(out.string).to include "mapper_parsing_exception: failed to parse"
    expect(a_request(:post, %r{/_bulk\z})).to have_been_made.twice
    expect(Sentry).to have_received(:capture_message)
  end

  it "stops the run when Elasticsearch can't be reached" do
    stub_request(:head, /tvfy_api_test_\d{4}\z/).to_raise(Faraday::ConnectionFailed.new("Connection refused"))
    allow(Sentry).to receive(:capture_exception)
    row(Time.utc(2023, 12, 5))
    row(Time.utc(2024, 1, 5))

    expect(described_class.run(from: nil, to: nil, out: out)).to be false
    expect(out.string).to include "Stopped"
    expect(a_request(:head, %r{/tvfy_api_test_2024\z})).not_to have_been_made
  end

  describe "choosing months" do
    before do
      row(Time.utc(2024, 1, 5))
      row(Time.utc(2024, 3, 5))
    end

    def months_sent
      bulk_lines.each_slice(2).map { |action, _document| action["index"]["_index"] }.uniq
    end

    it "copies every month with rows if given neither, saying how to narrow it" do
      expect(described_class.run(from: nil, to: nil, out: out)).to be true
      expect(out.string).to include "from 2024-01 to 2024-03", "FROM=YYYY-MM TO=YYYY-MM"
      expect(months_sent).to eq %w[tvfy_api_test_2024.01 tvfy_api_test_2024.03]
    end

    it "runs to the latest month with rows if given only FROM" do
      described_class.run(from: "2024-02", to: nil, out: out)
      expect(months_sent).to eq %w[tvfy_api_test_2024.03]
    end

    it "starts at the earliest month with rows if given only TO" do
      described_class.run(from: nil, to: "2024-02", out: out)
      expect(months_sent).to eq %w[tvfy_api_test_2024.01]
    end

    it "explains a badly formatted month" do
      expect(described_class.run(from: "2024-3", to: nil, out: out)).to be false
      expect(out.string).to include "\"2024-3\" isn't a month in the form YYYY-MM"
    end

    it "explains a range that ends before it starts" do
      expect(described_class.run(from: "2024-03", to: "2024-01", out: out)).to be false
      expect(out.string).to include "is after TO"
    end
  end
end

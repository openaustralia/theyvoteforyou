# frozen_string_literal: true

require "spec_helper"

# CI has no Elasticsearch, so its requests are stubbed. Rows, and ApiLog::Upload sending a month again, are real.
describe ApiLog::Trim do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }

  before do
    allow(Sentry).to receive(:capture_message)
    # The client checks it's talking to Elasticsearch before its first request
    stub_request(:get, %r{\Ahttp://[^/]+/\z}).to_return(
      json(version: { number: "7.17.7", build_flavor: "default" })
    )
    # What ApiLog::Upload asks for when sending a month again: no yearly index yet, create the monthly one, then send
    stub_request(:head, /tvfy_api_test_\d{4}\z/).to_return(status: 404)
    stub_request(:put, /tvfy_api_test_\d{4}\.\d{2}\z/).to_return(json({}))
    stub_request(:post, %r{/_bulk\z}).to_return(json(errors: false, items: []))
    stub_request(:post, %r{/_refresh\b})
  end

  def json(body)
    { body: body.to_json, headers: { "Content-Type" => "application/json", "X-Elastic-Product" => "Elasticsearch" } }
  end

  def call_at(time)
    ApiStatistic.create!(
      user: user, ip_address: "192.0.2.1", query: "/api/v1/policies.json", user_agent: "Example/1.0", created_at: time
    )
  end

  # Elasticsearch's answers to successive counts of the month's index
  def stub_count(month, *counts)
    counts.reduce(stub_request(:any, %r{/tvfy_api_test_#{month}/_count})) do |stub, count|
      stub.to_return(json(count: count))
    end
  end

  def trim
    result = nil
    expect { result = described_class.run }.to output.to_stdout
    result
  end

  describe "which months are trimmed" do
    let!(:start_of_october) { call_at(Time.utc(2026, 10, 1)) }

    before do
      call_at(Time.utc(2026, 9, 30, 23, 59, 59))
      stub_count("2026.09", 1)
      stub_count("2026.10", 1)
    end

    it "keeps the month that ended less than 30 days ago" do
      travel_to(Time.utc(2026, 11, 20, 12)) { expect(trim).to be true }
      expect(ApiStatistic.all).to eq [start_of_october]
    end

    it "keeps a month until a full 30 days after it ended" do
      travel_to(Time.utc(2026, 11, 30, 23, 59, 59)) { trim }
      expect(ApiStatistic.all).to eq [start_of_october]
    end

    it "trims a month 30 days after it ended" do
      travel_to(Time.utc(2026, 12, 1)) { trim }
      expect(ApiStatistic.count).to eq 0
    end
  end

  context "when Elasticsearch has every call in the month" do
    before do
      call_at(Time.utc(2026, 9, 10))
      call_at(Time.utc(2026, 9, 20))
      stub_count("2026.09", 2)
    end

    it "deletes the month's rows" do
      travel_to(Time.utc(2026, 11, 20)) { expect(trim).to be true }
      expect(ApiStatistic.count).to eq 0
    end

    it "says what it did" do
      travel_to(Time.utc(2026, 11, 20)) do
        expect { described_class.run }.to output("2026-09: 2 rows, 2 in Elasticsearch, deleted\n").to_stdout
      end
    end
  end

  context "when Elasticsearch is missing calls that sending the month again fills in" do
    let!(:rows) { [call_at(Time.utc(2026, 9, 10)), call_at(Time.utc(2026, 9, 20))] }

    before { stub_count("2026.09", 1, 2) }

    it "sends the month again, then deletes its rows" do
      travel_to(Time.utc(2026, 11, 20)) { expect(trim).to be true }
      sent = []
      expect(a_request(:post, %r{/_bulk\z}).with { |request| sent.concat(request.body.scan(/api_statistics-\d+/)) })
        .to have_been_made
      expect(sent).to eq(rows.map { |row| "api_statistics-#{row.id}" })
      expect(a_request(:post, %r{/tvfy_api_test_2026\.09/_refresh})).to have_been_made
      expect(ApiStatistic.count).to eq 0
    end
  end

  context "when the counts still differ after sending the month again" do
    let!(:august) { call_at(Time.utc(2026, 8, 10)) }

    before do
      call_at(Time.utc(2026, 9, 10))
      stub_count("2026.08", 0, 0)
      stub_count("2026.09", 1)
    end

    it "keeps that month, trims later ones, and returns false" do
      travel_to(Time.utc(2026, 11, 20)) { expect(trim).to be false }
      expect(ApiStatistic.all).to eq [august]
    end

    it "reports both counts to Sentry" do
      travel_to(Time.utc(2026, 11, 20)) { trim }
      expect(Sentry).to have_received(:capture_message)
        .with(anything, extra: { month: "2026-08", rows: 1, elasticsearch: 0 })
    end
  end

  context "when Elasticsearch can't be reached" do
    before do
      call_at(Time.utc(2026, 9, 10))
      stub_request(:any, /.*/).to_raise(Faraday::ConnectionFailed.new("Connection refused"))
    end

    it "deletes nothing, says why and returns false" do
      travel_to(Time.utc(2026, 11, 20)) do
        expect { expect(described_class.run).to be false }.to output(/couldn't be reached/).to_stdout
      end
      expect(ApiStatistic.count).to eq 1
    end
  end

  it "does nothing when there are no rows" do
    expect(described_class.run).to be true
  end
end

# frozen_string_literal: true

require "spec_helper"

describe "Logging API calls to Elasticsearch", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:confirmed_user) }
  let(:logged) { [] }
  let(:attempted_urls) { [] }
  # How many times Elasticsearch fails before it stores a document
  let(:failures) { 0 }
  let(:created_indices) { [] }
  let(:index_create_response) { { status: 200, headers: { "Content-Type" => "application/json" }, body: "{}" } }

  before do
    travel_to(Time.utc(2026, 11, 30, 23, 59, 59))
    Rails.configuration.x.log_api_calls_to_elasticsearch = true
    # The client first checks it's talking to Elasticsearch, and CI has none to answer
    stub_request(:get, %r{\Ahttps?://[^/]+/\z}).to_return(
      headers: { "Content-Type" => "application/json", "X-Elastic-Product" => "Elasticsearch" },
      body: { version: { number: "7.17.7" }, tagline: "You Know, for Search" }.to_json
    )
    stub_request(:put, %r{/tvfy_api_test_2026\.11\z}).to_return do |request|
      created_indices << JSON.parse(request.body)
      index_create_response
    end
    stub_request(:put, %r{/tvfy_api_test_2026\.11/_doc/[\w-]+\z}).to_return do |request|
      attempted_urls << request.uri.to_s
      next { status: 503, body: "{}" } if attempted_urls.size <= failures

      logged << JSON.parse(request.body)
      { status: 201, headers: { "Content-Type" => "application/json" }, body: "{}" }
    end
  end

  after { Rails.configuration.x.log_api_calls_to_elasticsearch = false }

  it "logs who made the call, where from, and when" do
    get "/api/v1/people.json", params: { key: user.api_key }, headers: { "User-Agent" => "Example client" }
    expect(logged.sole).to include(
      "user" => { "id" => user.id },
      "site" => "theyvoteforyou",
      "ip_address" => "127.0.0.1",
      "user_agent" => "Example client",
      "query_time" => "2026-11-30T23:59:59.000Z"
    )
  end

  it "logs the endpoint, path and parameters without the key" do
    division = create(:division)
    get "/api/v1/divisions/#{division.id}.json?ke%79=#{CGI.escape(user.api_key)}&house=senate"
    expect(logged.sole).to include(
      "endpoint" => "divisions#show",
      "query" => "/api/v1/divisions/#{division.id}.json?house=senate",
      "params" => { "id" => division.id.to_s, "format" => "json", "house" => "senate" }
    )
  end

  it "logs parameters sent as arrays or hashes as text, so they can't clash with the index's field types" do
    get "/api/v1/divisions.json?key=#{CGI.escape(user.api_key)}&house[]=senate"
    expect(logged.sole["params"]["house"]).to eq '["senate"]'
  end

  it "only logs parameters the API reads as fields, so made-up names can't fill the index's field limit" do
    get "/api/v1/divisions.json?key=#{CGI.escape(user.api_key)}&house=senate&made_up=1"
    expect(logged.sole).to include(
      "params" => { "format" => "json", "house" => "senate" },
      "query" => "/api/v1/divisions.json?house=senate&made_up=1"
    )
  end

  it "logs calls with a parameter named like ActiveJob's own serialisation keys" do
    get "/api/v1/people.json?key=#{CGI.escape(user.api_key)}&_aj_globalid=x"
    expect(logged.sole["query"]).to eq "/api/v1/people.json?_aj_globalid=x"
  end

  it "logs the id the API used when the query string also sends one" do
    division = create(:division)
    get "/api/v1/divisions/#{division.id}.json?key=#{CGI.escape(user.api_key)}&id=999"
    expect(logged.sole["params"]["id"]).to eq division.id.to_s
  end

  # Otherwise Elasticsearch guesses each field's type from a month's first call, so a field such as start_date could
  # be a date one month and text the next, which Kibana can't chart across months
  it "creates the month's index with fixed field types before logging to it" do
    get "/api/v1/people.json", params: { key: user.api_key }
    expect(created_indices.sole["mappings"]).to include(
      "date_detection" => false,
      "properties" => hash_including("query_time" => { "type" => "date" })
    )
  end

  it "makes every text value a keyword, so the same field can't be a date one month and text the next" do
    get "/api/v1/people.json", params: { key: user.api_key }
    strings_as_keywords = created_indices.sole["mappings"]["dynamic_templates"].sole["strings_as_keywords"]
    expect(strings_as_keywords).to include("match_mapping_type" => "string", "mapping" => hash_including("type" => "keyword"))
  end

  it "creates the month's index with the same settings as the search indices, so a one-node test cluster stays green" do
    get "/api/v1/people.json", params: { key: user.api_key }
    expect(created_indices.sole["settings"]).to eq SEARCHKICK_INDEX_SETTINGS.stringify_keys
  end

  context "when the month's index already exists" do
    let(:index_create_response) do
      { status: 400, headers: { "Content-Type" => "application/json" },
        body: { error: { type: "resource_already_exists_exception" }, status: 400 }.to_json }
    end

    it "still logs the call" do
      get "/api/v1/people.json", params: { key: user.api_key }
      expect(logged.size).to eq 1
    end
  end

  context "when Elasticsearch fails then recovers" do
    let(:failures) { 2 }

    it "stores the call once, however many tries it took" do
      get "/api/v1/people.json", params: { key: user.api_key }
      expect([logged.size, attempted_urls.size, attempted_urls.uniq.size]).to eq [1, 3, 1]
    end
  end

  context "when Elasticsearch keeps failing" do
    let(:failures) { 100 }

    it "gives up after 10 tries and reports it" do
      allow(Sentry).to receive(:capture_exception)
      get "/api/v1/people.json", params: { key: user.api_key }
      expect(attempted_urls.size).to eq 10
      expect(Sentry).to have_received(:capture_exception).once
    end
  end

  it "doesn't log calls with an invalid key" do
    get "/api/v1/people.json", params: { key: "not-a-key" }
    expect(logged).to be_empty
  end

  it "doesn't log calls when switched off" do
    Rails.configuration.x.log_api_calls_to_elasticsearch = false
    get "/api/v1/people.json", params: { key: user.api_key }
    expect(logged).to be_empty
  end
end

# frozen_string_literal: true

require "spec_helper"

describe "Logging API calls to Elasticsearch", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:confirmed_user) }
  let(:logged) { [] }

  before do
    travel_to(Time.utc(2026, 11, 30, 23, 59, 59))
    Rails.configuration.x.log_api_calls_to_elasticsearch = true
    stub_request(:post, %r{/tvfy-api-test-2026\.11/_doc\z}).to_return do |request|
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
    get "/api/v1/divisions/#{division.id}.json?ke%79=#{CGI.escape(user.api_key)}&extra=1"
    expect(logged.sole).to include(
      "endpoint" => "divisions#show",
      "query" => "/api/v1/divisions/#{division.id}.json?extra=1",
      "params" => { "id" => division.id.to_s, "format" => "json", "extra" => "1" }
    )
  end

  it "logs parameters sent as arrays or hashes as text, so they can't clash with the index's field types" do
    get "/api/v1/divisions.json?key=#{CGI.escape(user.api_key)}&house[]=senate"
    expect(logged.sole["params"]["house"]).to eq '["senate"]'
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

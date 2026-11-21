# frozen_string_literal: true

require "spec_helper"

describe "API usage counting", type: :request do
  let(:user) { create(:confirmed_user) }

  it "counts a request against the key's user for today (UTC)" do
    get "/api/v1/people.json", params: { key: user.api_key }
    expect(DailyApiUsage.find_by(user: user, date: Time.current.utc.to_date).count).to eq 1
  end

  it "logs the request against the key's user" do
    get "/api/v1/people.json", params: { key: user.api_key }
    expect(ApiStatistic.last.user).to eq user
  end

  it "logs the request without the key, keeping the other parameters as sent" do
    get "/api/v1/divisions.json?start_date=2021-07-01&key=#{CGI.escape(user.api_key)}&house=senate"
    expect(ApiStatistic.last.query).to eq "/api/v1/divisions.json?start_date=2021-07-01&house=senate"
  end

  it "doesn't log a key whose name is percent-encoded" do
    get "/api/v1/people.json?ke%79=#{CGI.escape(user.api_key)}"
    expect(ApiStatistic.last.query).to eq "/api/v1/people.json"
  end

  it "logs a request with only a key as the bare path" do
    get "/api/v1/people.json", params: { key: user.api_key }
    expect(ApiStatistic.last.query).to eq "/api/v1/people.json"
  end

  it "still answers the request if counting it fails" do
    allow(DailyApiUsage).to receive(:increment).and_raise(ActiveRecord::Deadlocked)
    get "/api/v1/people.json", params: { key: user.api_key }
    expect(response).to have_http_status(:ok)
  end

  it "still counts the request if logging it fails" do
    allow(ApiStatistic).to receive(:log).and_raise(ActiveRecord::Deadlocked)
    get "/api/v1/people.json", params: { key: user.api_key }
    expect(DailyApiUsage.find_by(user: user).count).to eq 1
  end

  context "when logging calls to Elasticsearch" do
    before do
      allow(Rails.configuration.x).to receive(:log_api_calls_to_elasticsearch).and_return(true)
      # CI has no Elasticsearch, so the job is checked as queued rather than run
      allow(LogApiCallJob).to receive(:perform_later)
    end

    it "sends the saved row" do
      get "/api/v1/people.json", params: { key: user.api_key }
      expect(LogApiCallJob).to have_received(:perform_later).with(ApiStatistic.last.id)
    end

    it "sends nothing if the row couldn't be saved" do
      allow(ApiStatistic).to receive(:log).and_raise(ActiveRecord::Deadlocked)
      get "/api/v1/people.json", params: { key: user.api_key }
      expect(LogApiCallJob).not_to have_received(:perform_later)
    end
  end

  it "rejects a key sent as an array" do
    get "/api/v1/people.json", params: { key: [user.api_key] }
    expect(response).to have_http_status(:unauthorized)
  end

  it "doesn't count a request with an invalid key" do
    get "/api/v1/people.json", params: { key: "not-a-key" }
    expect(DailyApiUsage.count).to eq 0
  end
end

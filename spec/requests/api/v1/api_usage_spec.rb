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

  it "rejects a key sent as an array" do
    get "/api/v1/people.json", params: { key: [user.api_key] }
    expect(response).to have_http_status(:unauthorized)
  end

  it "doesn't count a request with an invalid key" do
    get "/api/v1/people.json", params: { key: "not-a-key" }
    expect(DailyApiUsage.count).to eq 0
  end
end

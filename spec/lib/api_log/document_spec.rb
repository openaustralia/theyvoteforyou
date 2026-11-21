# frozen_string_literal: true

require "spec_helper"

describe ApiLog::Document do
  let(:user) { create(:confirmed_user) }

  def logged(query)
    ApiStatistic.create!(user: user, query: query, ip_address: "203.0.113.7", user_agent: "Example/1.0",
                         created_at: Time.utc(2014, 3, 31, 23, 59))
  end

  describe ".build" do
    it "copies the row's fields" do
      expect(described_class.build(logged("/api/v1/people.json"))).to eq(
        site: "theyvoteforyou", user: { id: user.id }, endpoint: "people#index", query: "/api/v1/people.json",
        params: { "format" => "json" }, ip_address: "203.0.113.7", user_agent: "Example/1.0",
        query_time: Time.utc(2014, 3, 31, 23, 59)
      )
    end

    it "takes the endpoint and id from the route" do
      document = described_class.build(logged("/api/v1/divisions/42.json"))
      expect(document.values_at(:endpoint, :params)).to eq ["divisions#show", { "id" => "42", "format" => "json" }]
    end

    it "keeps only the parameters the API reads" do
      document = described_class.build(logged("/api/v1/divisions.json?house=senate&made_up=1"))
      expect(document[:params]).to eq("house" => "senate", "format" => "json")
    end

    it "removes a key still held in an older row" do
      document = described_class.build(logged("/api/v1/people.json?key=abc123&house=senate"))
      expect(document[:query]).to eq "/api/v1/people.json?house=senate"
    end

    it "logs a parameter sent as an array as text" do
      document = described_class.build(logged("/api/v1/divisions.json?house[]=senate"))
      expect(document[:params]["house"]).to eq '["senate"]'
    end

    it "keeps the route's id over one in the query string" do
      expect(described_class.build(logged("/api/v1/people/1.json?id=2"))[:params]["id"]).to eq "1"
    end

    it "logs a path the routes no longer serve as unknown, with its query string's parameters" do
      document = described_class.build(logged("/api/v1/bills.json?house=senate"))
      expect(document.values_at(:endpoint, :params)).to eq ["unknown", { "house" => "senate" }]
    end

    it "doesn't count a non-API page as an endpoint" do
      expect(described_class.build(logged("/people"))[:endpoint]).to eq "unknown"
    end

    it "copies a row whose query string can't be parsed, without its parameters" do
      expect(described_class.build(logged("/api/v1/people.json?house=%"))[:params]).to eq("format" => "json")
    end
  end

  it "stores each row under an id taken from it, so sending it again replaces it" do
    api_statistic = logged("/api/v1/people.json")
    expect(described_class.id(api_statistic)).to eq "api_statistics-#{api_statistic.id}"
  end
end

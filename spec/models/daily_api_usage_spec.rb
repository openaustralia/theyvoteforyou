# frozen_string_literal: true

require "spec_helper"

describe DailyApiUsage do
  let(:user) { create(:confirmed_user) }
  let(:other_user) { create(:confirmed_user) }

  describe ".increment" do
    it "starts a new day at one" do
      described_class.increment(user: user, date: Date.new(2026, 10, 1))
      expect(described_class.find_by(user: user, date: Date.new(2026, 10, 1)).count).to eq 1
    end

    it "adds to an existing day" do
      2.times { described_class.increment(user: user, date: Date.new(2026, 10, 1)) }
      expect(described_class.find_by(user: user, date: Date.new(2026, 10, 1)).count).to eq 2
    end

    it "keeps each day separate" do
      described_class.increment(user: user, date: Date.new(2026, 10, 1))
      described_class.increment(user: user, date: Date.new(2026, 10, 2))
      expect(described_class.where(user: user).pluck(:count)).to eq [1, 1]
    end
  end

  describe ".top_users" do
    before do
      described_class.create!(user: user, date: Date.new(2026, 10, 1), count: 10)
      described_class.create!(user: user, date: Date.new(2026, 10, 2), count: 20)
      described_class.create!(user: other_user, date: Date.new(2026, 10, 2), count: 50)
      described_class.create!(user: other_user, date: Date.new(2026, 9, 30), count: 1000)
    end

    let(:result) { described_class.top_users(from: Date.new(2026, 10, 1), to: Date.new(2026, 10, 2)) }

    it "lists the busiest users first, ignoring days outside the range" do
      expect(result.map(&:user)).to eq [other_user, user]
    end

    it "averages over every day in the range, counting quiet days as zero" do
      expect(result.map { |r| [r.total, r.mean, r.min, r.max] }).to eq [[50, 25.0, 0, 50], [30, 15.0, 10, 20]]
    end

    it "limits the number of users" do
      expect(described_class.top_users(from: Date.new(2026, 10, 1), to: Date.new(2026, 10, 2), limit: 1).size).to eq 1
    end
  end

  describe ".rebuild_month" do
    def log_request(user, time)
      ApiStatistic.create!(user: user, query: "/api/v1/people.json", created_at: time)
    end

    before do
      log_request(user, Time.utc(2026, 10, 1, 1))
      log_request(user, Time.utc(2026, 10, 1, 23))
      log_request(other_user, Time.utc(2026, 10, 31, 23, 59))
      log_request(user, Time.utc(2026, 11, 1))
      described_class.create!(user: user, date: Date.new(2026, 10, 1), count: 99)
      described_class.rebuild_month(Date.new(2026, 10, 1))
    end

    it "replaces the month's counts with those in api_statistics, by UTC day" do
      expect(described_class.order(:date).pluck(:user_id, :date, :count)).to eq [
        [user.id, Date.new(2026, 10, 1), 2],
        [other_user.id, Date.new(2026, 10, 31), 1]
      ]
    end
  end
end

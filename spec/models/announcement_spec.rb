# frozen_string_literal: true

require "spec_helper"

describe Announcement do
  include ActiveSupport::Testing::TimeHelpers

  before { travel_to(Time.zone.local(2026, 10, 15, 12, 0, 0)) }

  describe "validations" do
    it "needs a body" do
      expect(build(:announcement, body: "")).not_to be_valid
    end

    it "needs an end that falls after the start" do
      announcement = build(:announcement, starts_at: 1.hour.from_now, ends_at: 1.hour.ago)
      expect(announcement).not_to be_valid
    end

    it "allows a start with no end, and an end with no start" do
      expect(build(:announcement, starts_at: 1.hour.ago, ends_at: nil)).to be_valid
      expect(build(:announcement, starts_at: nil, ends_at: 1.hour.from_now)).to be_valid
    end
  end

  describe ".live" do
    it "includes a published announcement with no dates" do
      announcement = create(:announcement)
      expect(described_class.live).to contain_exactly(announcement)
    end

    it "excludes an unpublished announcement" do
      create(:announcement, published: false)
      expect(described_class.live).to be_empty
    end

    it "excludes an announcement that has not started yet" do
      create(:announcement, starts_at: 1.minute.from_now)
      expect(described_class.live).to be_empty
    end

    it "excludes an announcement that has ended" do
      create(:announcement, ends_at: 1.minute.ago)
      expect(described_class.live).to be_empty
    end

    it "includes an announcement inside its start and end" do
      announcement = create(:announcement, starts_at: 1.hour.ago, ends_at: 1.hour.from_now)
      expect(described_class.live).to contain_exactly(announcement)
    end

    it "includes an announcement at the moment it starts and excludes it at the moment it ends" do
      starting = create(:announcement, starts_at: Time.current)
      create(:announcement, ends_at: Time.current)
      expect(described_class.live).to contain_exactly(starting)
    end
  end

  describe ".current" do
    it "is nil when nothing is live" do
      create(:announcement, published: false)
      expect(described_class.current).to be_nil
    end

    it "is the newest live announcement" do
      create(:announcement, body: "Older", created_at: 2.days.ago)
      newest = create(:announcement, body: "Newer", created_at: 1.day.ago)
      create(:announcement, body: "Newest but unpublished", published: false, created_at: 1.hour.ago)
      expect(described_class.current).to eq newest
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

describe PolicyPersonDistance do
  describe ".category" do
    it "no votes" do
      ppd = described_class.new
      expect(ppd.category).to eq :not_enough
    end

    it "one normal vote" do
      ppd = described_class.new(nvotessame: 1)
      expect(ppd.category).to eq :not_enough
    end

    it "one normal vote and 3 absent votes" do
      ppd = described_class.new(nvotessame: 1, nvotesabsent: 3)
      expect(ppd.category).to eq :not_enough
    end

    it "two normal votes" do
      ppd = described_class.new(nvotessame: 2, distance_a: 0.04)
      expect(ppd.category).to eq :for3
    end

    it "three normal votes" do
      ppd = described_class.new(nvotessame: 3, distance_a: 0.04)
      expect(ppd.category).to eq :for3
    end

    it "one strong vote" do
      ppd = described_class.new(nvotessamestrong: 1, distance_a: 0)
      expect(ppd.category).to eq :for3
    end

    it "distance 0.1" do
      ppd = described_class.new(nvotessame: 3, distance_a: 0.1)
      expect(ppd.category).to eq :for2
    end

    it "distance 0.3" do
      ppd = described_class.new(nvotessame: 3, distance_a: 0.3)
      expect(ppd.category).to eq :for1
    end

    it "distance 0.5" do
      ppd = described_class.new(nvotessame: 3, distance_a: 0.5)
      expect(ppd.category).to eq :mixture
    end

    it "distance 0.7" do
      ppd = described_class.new(nvotessame: 3, distance_a: 0.7)
      expect(ppd.category).to eq :against1
    end

    it "distance 0.9" do
      ppd = described_class.new(nvotessame: 3, distance_a: 0.9)
      expect(ppd.category).to eq :against2
    end

    it "distance 0.96" do
      ppd = described_class.new(nvotessame: 3, distance_a: 0.96)
      expect(ppd.category).to eq :against3
    end
  end
end

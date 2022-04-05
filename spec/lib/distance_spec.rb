# frozen_string_literal: true

require "spec_helper"

describe Distance do
  describe ".distance" do
    context "when no absent votes" do
      context "when two members that have never voted on the same thing" do
        it { expect(described_class.new(same: 0, differ: 0, absent: 0).distance).to eq(-1) }
      end

      context "with two members always agreeing" do
        it { expect(described_class.new(same: 3).distance).to eq 0 }
        it { expect(described_class.new(same: 10).distance).to eq 0 }
      end

      context "with two members always disagreeing" do
        it { expect(described_class.new(differ: 3).distance).to eq 1 }
        it { expect(described_class.new(differ: 10).distance).to eq 1 }
      end

      context "with two members agreeing half the time" do
        it { expect(described_class.new(same: 3, differ: 3).distance).to eq 0.5 }
        it { expect(described_class.new(same: 10, differ: 10).distance).to eq 0.5 }
      end

      it { expect(described_class.new(same: 3, differ: 1).distance).to eq 0.25 }
    end

    context "when only absent votes" do
      it "sees them as neither agreeing or disagreeing" do
        expect(described_class.new(absent: 3).distance).to eq 0.5
      end
    end

    # With 5 absent votes versus 1 agree vote we are half way between agreeing completely (0)
    # and what we would get by both parties being absent all the time (0.5)
    it { expect(described_class.new(same: 1, absent: 5).distance).to eq 0.25 }
    # Similarly here for disagreeing
    it { expect(described_class.new(differ: 1, absent: 5).distance).to eq 0.75 }
  end

  describe ".agreement" do
    context "when only strongly agreeing" do
      it { expect(described_class.new(samestrong: 3).agreement).to eq 1.0 }
      it { expect(described_class.new(samestrong: 10).agreement).to eq 1.0 }
    end

    context "when only strongly disagreeing" do
      it { expect(described_class.new(differstrong: 3).agreement).to eq 0.0 }
      it { expect(described_class.new(differstrong: 10).agreement).to eq 0.0 }
    end

    context "when only strongly absent" do
      it { expect(described_class.new(absentstrong: 3).agreement).to eq 0.5 }
      it { expect(described_class.new(absentstrong: 10).agreement).to eq 0.5 }
    end

    context "when equal number of strong agreements and strong disagreements" do
      it { expect(described_class.new(samestrong: 3, differstrong: 3).agreement).to eq 0.5 }
      it { expect(described_class.new(samestrong: 10, differstrong: 10).agreement).to eq 0.5 }
    end

    context "when 1 strong agreement and 5 regular disagreements" do
      it { expect(described_class.new(samestrong: 1, differ: 5).agreement).to eq 0.5 }
    end

    context "when 5 agreements and 1 strong disagreement" do
      it { expect(described_class.new(same: 5, differstrong: 1).agreement).to eq 0.5 }
    end

    context "when 5 agreements and 1 strong absent" do
      it { expect(described_class.new(same: 5, absentstrong: 1).agreement).to eq 0.75 }
    end
  end

  describe ".points" do
    it { expect(described_class.points(:same)).to eq 10 }
    it { expect(described_class.points(:differ)).to eq 0 }
    it { expect(described_class.points(:absent)).to eq 1 }
    it { expect(described_class.points(:samestrong)).to eq 50 }
    it { expect(described_class.points(:differstrong)).to eq 0 }
    it { expect(described_class.points(:absentstrong)).to eq 25 }
  end

  describe ".possible_points" do
    it { expect(described_class.possible_points(:same)).to eq 10 }
    it { expect(described_class.possible_points(:differ)).to eq 10 }
    it { expect(described_class.possible_points(:absent)).to eq 2 }
    it { expect(described_class.possible_points(:samestrong)).to eq 50 }
    it { expect(described_class.possible_points(:differstrong)).to eq 50 }
    it { expect(described_class.possible_points(:absentstrong)).to eq 50 }
  end

  describe "#total_points" do
    let(:distance) { described_class.new(same: 1, differ: 2, absent: 3, samestrong: 4, differstrong: 5, absentstrong: 6) }

    it { expect(distance.total_points).to eq 363 }
  end

  describe "#possible_total_points" do
    let(:distance) { described_class.new(same: 1, differ: 2, absent: 3, samestrong: 4, differstrong: 5, absentstrong: 6) }

    it { expect(distance.possible_total_points).to eq 786 }
  end
end

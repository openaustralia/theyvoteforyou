require 'spec_helper'

describe Distance do
  describe ".distance_b" do
    context "two members that have never voted on the same thing" do
      it { expect(Distance.distance_b(0, 0)).to eq -1 }
    end

    context "two members always agreeing" do
      it { expect(Distance.distance_b(3, 0)).to eq 0 }
      it { expect(Distance.distance_b(10, 0)).to eq 0 }
    end

    context "two members always disagreeing" do
      it { expect(Distance.distance_b(0, 3)).to eq 1 }
      it { expect(Distance.distance_b(0, 10)).to eq 1 }
    end

    context "two members agreeing half the time" do
      it { expect(Distance.distance_b(3, 3)).to eq 0.5 }
      it { expect(Distance.distance_b(10, 10)).to eq 0.5 }
    end

    it { expect(Distance.distance_b(3, 1)).to eq 0.25 }
  end

  describe ".distance_a" do
    context "no absent votes" do
      it { expect(Distance.distance_a(3, 1, 0)).to eq Distance.distance_b(3, 1)}
    end

    context "only absent votes" do
      it "should see them as neither agreeing or disagreeing" do
        expect(Distance.distance_a(0, 0, 3)).to eq 0.5
      end
    end

    # With 5 absent votes versus 1 agree vote we are half way between agreeing completely (0)
    # and what we would get by both parties being absent all the time (0.5)
    it { expect(Distance.distance_a(1, 0, 5)).to eq 0.25}
    # Similarly here for disagreeing
    it { expect(Distance.distance_a(0, 1, 5)).to eq 0.75}
  end

  describe ".agreement" do
    context "only strongly agreeing" do
      it { expect(Distance.new(0, 3, 0, 0, 0, 0).agreement).to eq 1.0}
      it { expect(Distance.new(0, 10, 0, 0, 0, 0).agreement).to eq 1.0}
    end

    context "only strongly disagreeing" do
      it { expect(Distance.new(0, 0, 0, 3, 0, 0).agreement).to eq 0.0}
      it { expect(Distance.new(0, 0, 0, 10, 0, 0).agreement).to eq 0.0}
    end

    context "only strongly absent" do
      it { expect(Distance.new(0, 0, 0, 0, 0, 3).agreement).to eq 0.5}
      it { expect(Distance.new(0, 0, 0, 0, 0, 10).agreement).to eq 0.5}
    end

    context "equal number of strong agreements and strong disagreements" do
      it { expect(Distance.new(0, 3, 0, 3, 0, 0).agreement).to eq 0.5}
      it { expect(Distance.new(0, 10, 0, 10, 0, 0).agreement).to eq 0.5}
    end

    context "1 strong agreement and 5 regular disagreements" do
      it { expect(Distance.new(0, 1, 5, 0, 0, 0).agreement).to eq 0.5}
    end

    context "5 agreements and 1 strong disagreement" do
      it { expect(Distance.new(5, 0, 0, 1, 0, 0).agreement).to eq 0.5}
    end

    context "5 agreements and 1 strong absent" do
      it { expect(Distance.new(5, 0, 0, 0, 0, 1).agreement).to eq 0.75}
    end
  end

  describe ".points" do
    it do
      expect(Distance.points).to eq ({
          same: 10, differ: 0, absent: 1,
          samestrong: 50, differstrong: 0, absentstrong: 25
        })
    end
  end

  describe ".possible_points" do
    it do
      expect(Distance.possible_points).to eq ({
          same: 10, differ: 10, absent: 2,
          samestrong: 50, differstrong: 50, absentstrong: 50
        })
    end
  end

  describe "#votes_points" do
    # TODO Not yet testing strong votes
    let(:distance) { Distance.new(1, 0, 2, 0, 3, 0) }
    it { expect(distance.votes_points(:same)).to eq 10}
    it { expect(distance.votes_points(:differ)).to eq 0}
    it { expect(distance.votes_points(:absent)).to eq 3}
    it { expect(distance.votes_points(:samestrong)).to eq 0}
    it { expect(distance.votes_points(:differstrong)).to eq 0}
    it { expect(distance.votes_points(:absentstrong)).to eq 0}
  end

  describe "#possible_votes_points" do
    # TODO Not yet testing strong votes
    let(:distance) { Distance.new(1, 0, 2, 0, 3, 0) }
    it { expect(distance.possible_votes_points(:same)).to eq 10}
    it { expect(distance.possible_votes_points(:differ)).to eq 20}
    it { expect(distance.possible_votes_points(:absent)).to eq 6}
    it { expect(distance.possible_votes_points(:samestrong)).to eq 0}
    it { expect(distance.possible_votes_points(:differstrong)).to eq 0}
    it { expect(distance.possible_votes_points(:absentstrong)).to eq 0}
  end
end

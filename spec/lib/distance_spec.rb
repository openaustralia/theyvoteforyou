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
end

require 'spec_helper'

describe Policy, :type => :model do
  describe '#update_division_vote!' do
    fixtures :policies
    let(:division) { mock_model(Division) }
    let(:policy) { policies(:two) }

    it {
      expect(policy).to receive(:vote_for_division).with(division).and_return(nil)
      expect(policy.update_division_vote!(division, nil)).to be_nil
    }
    it {
      expect(policy).to receive(:vote_for_division).with(division).and_return("no3")
      expect(policy.update_division_vote!(division, 'aye3')).to eq('no3')
    }
  end
end

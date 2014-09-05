require 'spec_helper'

describe Policy, :type => :model do
  describe '#update_division_vote!' do
    fixtures :policies

    it { expect(policies(:two).update_division_vote!(mock_model(Division), nil, nil)).to be_nil }
    it { expect(policies(:two).update_division_vote!(mock_model(Division), 'no3', 'aye3')).to eq('no3') }
  end
end

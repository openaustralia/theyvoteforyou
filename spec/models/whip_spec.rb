require 'spec_helper'

describe Whip, :type => :model do
  describe '#whip_guess_majority' do
    it 'whip guess is aye and noes are in the majority' do
      allow(subject).to receive(:whip_guess).and_return("aye")
      allow(subject).to receive(:noes_in_majority?).and_return(true)
      expect(subject.whip_guess_majority).to eq('minority')
    end
  end
end

require 'spec_helper'

describe Whip do
  describe '#whip_guess_majority' do
    it 'whip guess is aye and noes are in the majority' do
      subject.stub(:whip_guess).and_return("aye")
      subject.stub(:noes_in_majority?).and_return(true)
      subject.whip_guess_majority.should == 'minority'
    end
  end
end

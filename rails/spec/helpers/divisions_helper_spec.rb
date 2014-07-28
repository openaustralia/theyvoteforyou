require 'spec_helper'

describe DivisionsHelper do
  describe '#formatted_motion_text' do
    subject { formatted_motion_text division }

    let(:division) { mock_model(Division, motion: "A bill [No. 2] and votes") }
    it { should eq("<p>A bill [No. 2] and votes</p>\n") }
  end
end

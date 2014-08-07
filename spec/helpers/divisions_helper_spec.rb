require 'spec_helper'

describe DivisionsHelper do
  describe '#formatted_motion_text' do
    it { formatted_motion_text(mock_model(Division, motion: "A bill [No. 2] and votes")).should eq("<p>A bill [No. 2] and votes</p>\n") }
    it { formatted_motion_text(mock_model(Division, motion: "This remark[1] deserves a footnote")).should eq("<p>This remark<sup class=\"sup-1\"><a class=\"sup\" href='#footnote-1' onclick=\"ClickSup(1); return false;\">[1]</a></sup> deserves a footnote</p>\n") }
  end
end

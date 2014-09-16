require 'spec_helper'

describe Division, :type => :model do
  describe '#formatted_motion_text' do
    it do
      division = Division.new(motion: "A bill [No. 2] and votes")
      expect(division.formatted_motion_text).to eq("<p>A bill [No. 2] and votes</p>\n")
    end
    it do
      division = Division.new(motion: "This remark[1] deserves a footnote")
      expect(division.formatted_motion_text).to eq("<p>This remark<sup class=\"sup-1\"><a class=\"sup\" href='#footnote-1' onclick=\"ClickSup(1); return false;\">[1]</a></sup> deserves a footnote</p>\n")
    end
  end

  describe '#passed?' do
    subject(:division) { Division.new }

    it "should not be passed when there's a draw" do
      allow(division).to receive(:aye_majority) {0}
      expect(division.passed?).to be(false)
    end
  end
end

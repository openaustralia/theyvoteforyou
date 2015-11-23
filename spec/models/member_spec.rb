require 'spec_helper'

describe Member, type: :model do
  before :each do
    # TODO: Work out why fixtures are loaded - we don't want them
    Member.delete_all
  end

  describe ".current_on" do
    it "should only return the latest one when there's an overlap" do
      member = create(:member, entered_house: "2015-11-23", left_house: "9999-12-31")
      create(:member, entered_house: "2015-01-01", left_house: "2015-11-23", person: member.person)
      expect(Member.current_on(Date.new(2015, 11, 23)).to_a).to eql [member]
    end
  end
end

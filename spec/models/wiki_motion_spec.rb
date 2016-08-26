require 'spec_helper'

describe WikiMotion, type: :model do
  # TODO Figure out why we need to do this horrible hack to remove the fixtures
  # we shouldn't have them loaded
  before :each do
    WikiMotion.delete_all
  end

  describe 'storing edit_date in local time zone' do
    it "magical high level test" do
      wiki_motion = create(:wiki_motion, edit_date: Time.new(2014,1,1,1,1,1))

      expect(wiki_motion.edit_date.strftime('%F %T')).to eq "2014-01-01 01:01:01"
    end
  end

  describe "#edit_date" do
    # let(:wiki_motion) { create(:wiki_motion, edit_date: Time.new(2014,1,1,1,1,1)) }

    context "when the local time is 2016-08-23 17:41" do
      before do
        Timecop.freeze(Time.new(2016,8,23,17,41))
      end

      after do
        Timecop.return
      end

      it "writes the edit_date to the db as 2016-08-23 17:41 UTC" do
        create(:wiki_motion, edit_date: Time.now)

        sql = "SELECT edit_date from wiki_motions;"
        raw_date_in_db = ActiveRecord::Base.connection.execute(sql).first.first

        expect(raw_date_in_db).to eq "2016-08-23 17:41:00 UTC"
      end
    end
  end

  describe "#edit_date_without_timezone" do
    it "is edit_date formatted to have no timezone" do
      wiki_motion = create(:wiki_motion, edit_date: Time.new(2014,1,1,1,1,1,1))

      expect(wiki_motion.edit_date_without_timezone).to eq "2014-01-01 01:01:01"
    end
  end
end

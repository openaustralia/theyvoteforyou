require 'spec_helper'

describe WikiMotion, type: :model do
  before :each do
    # TODO: Find a way to reliably return a specific WikiMotion from the DB and use that at L35
    WikiMotion.delete_all
  end

  describe 'storing edit_date in local time zone' do
    it "magical high level test" do
      wiki_motion = create(:wiki_motion, edit_date: Time.new(2014,1,1,1,1,1))

      expect(wiki_motion.edit_date.strftime('%F %T')).to eq "2014-01-01 01:01:01"
    end
  end

  describe "#edit_date" do
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

      it "matches what was written when read" do
        wiki_motion = create(:wiki_motion, edit_date: Time.new(2016,8,23,17,41))

        expect(wiki_motion.edit_date).to eq Time.new(2016,8,23,17,41)
      end

      it "matches in value in the database without timezone when read" do
        wiki_motion = create(:wiki_motion, edit_date: Time.new(2016,8,23,17,41))

        sql = "SELECT edit_date from wiki_motions;"
        raw_date_in_db = ActiveRecord::Base.connection.execute(sql).first.first

        expect(wiki_motion.edit_date.strftime('%F %T'))
          .to eq raw_date_in_db.strftime('%F %T')
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

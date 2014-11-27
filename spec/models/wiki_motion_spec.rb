require 'spec_helper'

describe WikiMotion, type: :model do
  describe 'storing edit_date in local time zone' do
    it { expect(create(:wiki_motion, edit_date: Time.new(2014,1,1,1,1,1)).edit_date.strftime('%F %T')).to eq "2014-01-01 01:01:01" }
  end
end

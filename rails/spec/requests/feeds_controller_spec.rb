require 'spec_helper'

describe FeedsController do
  include HTMLCompareHelper
  fixtures :all

  describe '#mp-info' do
    it { compare '/feeds/mp-info.xml' }
    # it { compare '/feeds/mp-info.xml?house=lords' }
  end

  describe '#mpdream-info' do
    # it { compare '/feeds/mpdream-info.xml?id=1' }
    # it { compare '/feeds/mpdream-info.xml?id=2' }
  end
end

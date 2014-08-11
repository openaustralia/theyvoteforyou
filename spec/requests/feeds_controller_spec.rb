require 'spec_helper'

describe FeedsController, :type => :request do
  include HTMLCompareHelper
  fixtures :all

  describe '#mp-info' do
    it { compare_static '/feeds/mp-info.xml' }
    it { compare_static '/feeds/mp-info.xml?house=lords' }
  end

  describe '#mpdream-info' do
    it { compare_static '/feeds/mpdream-info.xml?id=1' }
    it { compare_static '/feeds/mpdream-info.xml?id=2' }
  end
end

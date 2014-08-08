require 'spec_helper'

describe FeedsController, :type => :request do
  include HTMLCompareHelper
  fixtures :all

  before :each do
    # The PHP app uses cache tables for rankings that aren't part of our fixtures
    # whereas the Rails app dynamically generates these rankings so we need to update
    # those caches before we run these tests
    `cd #{::Rails.root}/php/loader && ./calc_caches.php`
  end

  describe '#mp-info' do
    it { compare_static '/feeds/mp-info.xml' }
    it { compare_static '/feeds/mp-info.xml?house=lords' }
  end

  describe '#mpdream-info' do
    it { compare_static '/feeds/mpdream-info.xml?id=1' }
    it { compare '/feeds/mpdream-info.xml?id=2' }
  end
end

require 'spec_helper'

describe FeedsController, type: :request do
  include HTMLCompareHelper

  describe '#mp-info' do
    it { compare_static('/feeds/mp-info.xml', false, false, "", :post, "xml") }
    it { compare_static('/feeds/mp-info.xml?house=senate', false, false, "", :post, "xml") }
  end

  describe '#mpdream-info' do
    it { compare_static('/feeds/mpdream-info.xml?id=1', false, false, "", :post, "xml") }
    # This test is commented out because it occasionally fails on travis for unknown reasons
    # It doesn't fail when run locally
    # TODO Reinstate this test
    #it { compare_static '/feeds/mpdream-info.xml?id=2' }
  end
end

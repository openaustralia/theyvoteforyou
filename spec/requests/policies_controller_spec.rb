require 'spec_helper'
# Compare results of rendering pages via rails and via the old php app

describe PoliciesController, type: :request do
  include HTMLCompareHelper
  fixtures :all

  before(:each) do
    DatabaseCleaner.start
  end

  after(:each) do
    DatabaseCleaner.clean
  end

  it "#index" do
    compare_static("/policies.php")
  end

  describe "#show" do
    it { compare_static("/policy.php?id=1") }
    it { compare_static("/policy.php?id=1&display=motions") }

    it { compare_static("/policy.php?id=2") }
    it { compare_static("/policy.php?id=2&display=motions") }
  end

  describe '#add' do
    it { compare_static '/policies', true, {commit: 'Make Policy', policy: {name: '', description: 'nuclear power is great.'}}, "_2" }
    it { compare_static '/policies', true, {commit: 'Make Policy', policy: {name: 'nuclear power', description: ''}}, "_3" }
  end
end

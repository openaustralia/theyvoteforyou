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

  describe '#update', versioning: true do
    it { compare_static '/policies/1', true, {submit: 'Save title and text', name: 'marriage inequality', description: 'access to marriage should be inequal', provisional: 'provisional'}, "", :put}
    it { compare_static '/policies/2', true, {submit: 'Save title and text', name: 'onshore processing', description: 'refugees arrving by boat should be processed onshore'}, "", :put}

    it { compare_static '/policies/2', true, {submit: 'Save title and text', name: '', description: 'a useful description'}, "_2", :put }
    it { compare_static '/policies/2', true, {submit: 'Save title and text', name: 'A useful title', description: ''}, "_3", :put }
  end
end

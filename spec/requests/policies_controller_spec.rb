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
    it { compare_static("/policy.php?id=1&display=editdefinition", true) }

    it { compare_static("/policy.php?id=2") }
    it { compare_static("/policy.php?id=2&display=motions") }
    it { compare_static("/policy.php?id=2&display=editdefinition", true) }
  end

  describe '#add' do
    # The PHP app does something really silly when we're not logged in,
    # it turns this page into a login page. We're going to redirect to the
    # login page instead (which redirects back here after login) so disabling
    # this test
    #it { compare url }

    it { compare_static '/policies/new', true, false }

    it { compare_static '/policies', true, {commit: 'Make Policy', policy: {name: 'nuclear power', description: 'nuclear power is great.'}} }

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

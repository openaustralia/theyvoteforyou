require 'spec_helper'
# Compare results of rendering pages via rails and via the old php app

describe PoliciesController do
  include HTMLCompareHelper
  fixtures :all

  it "#index" do
    compare("/policies.php")
  end

  describe "#show" do
    it { compare("/policy.php?id=1") }
    it { compare("/policy.php?id=1&display=motions") }
    it { compare("/policy.php?id=1&display=editdefinition", true) }

    it { compare("/policy.php?id=2") }
    it { compare("/policy.php?id=2&display=motions") }
    it { compare("/policy.php?id=2&display=editdefinition", true) }
  end

  describe '#add' do
    let(:url) { '/account/addpolicy.php' }

    # The PHP app does something really silly when we're not logged in,
    # it turns this page into a login page. We're going to redirect to the
    # login page instead (which redirects back here after login) so disabling
    # this test
    #it { compare url }

    it { compare url, true }

    it { compare_static url, true, submit: 'Make Policy', name: 'Pro-nuclear power', description: 'nuclear power is great.' }

    it { compare_post url, true, submit: 'Make Policy', name: '', description: 'nuclear power is great.' }
    it { compare_post url, true, submit: 'Make Policy', name: 'Pro-nuclear power', description: '' }
  end
end

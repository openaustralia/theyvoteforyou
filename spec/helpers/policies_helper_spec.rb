require 'spec_helper'

describe PoliciesHelper, :type => :helper do
  before :each do
    User.delete_all
    Policy.delete_all
  end

  describe ".policies_list_sentence" do
    let(:user) { User.create!(email: "matthew@oaf.org.au", password: "foofoofoo") }
    let(:policy1) { Policy.create!(id: 1, name: "A nice policy", description: "nice", user: user, private: 0) }
    let(:policy2) { Policy.create!(id: 2, name: "A provisional policy", description: "prov", user: user, private: 2) }

    it { expect(policies_list_sentence([policy1])).to eq '<a href="policy.php?id=1">A nice policy</a>' }
    it { expect(policies_list_sentence([policy2])).to eq '<a href="policy.php?id=2">A provisional policy</a> <i>(provisional)</i>'}
    it { expect(policies_list_sentence([policy1, policy2])).to eq '<a href="policy.php?id=1">A nice policy</a> and <a href="policy.php?id=2">A provisional policy</a> <i>(provisional)</i>'}
  end
end

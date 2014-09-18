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
    let(:policy3) { Policy.create!(id: 3, name: "<em>A</em> provisional policy", description: "prov", user: user, private: 2) }

    it { expect(helper.policies_list_sentence([policy1])).to eq '<a href="/policies/1">A nice policy</a>' }
    it { expect(helper.policies_list_sentence([policy2])).to eq '<a href="/policies/2">A provisional policy</a> <i>(provisional)</i>'}
    it { expect(helper.policies_list_sentence([policy3])).to eq '<a href="/policies/3">&lt;em&gt;A&lt;/em&gt; provisional policy</a> <i>(provisional)</i>'}
    it { expect(helper.policies_list_sentence([policy3])).to be_html_safe }
    it { expect(helper.policies_list_sentence([policy1, policy2])).to eq '<a href="/policies/1">A nice policy</a> and <a href="/policies/2">A provisional policy</a> <i>(provisional)</i>'}
  end

  describe ".version_sentence" do
    before :each do
      expect(User).to receive(:find).with(1).and_return(double("user", real_name: "Matthew"))
    end

    it "create provisional policy" do
      version = double("version", item_type: "Policy", event: "create", whodunnit: 1, created_at: 1.hour.ago, changeset: {"name" => [nil, "A new policy"], "description" => [nil, "Oh yes!"], "private" => [nil, 2], "id" => [nil, 3]})
      expect(helper.version_sentence(version)).to eq "Created provisional policy &ldquo;A new policy&rdquo; with description &ldquo;Oh yes!&rdquo; by Matthew, about 1 hour ago"
    end

    it "create policy" do
      version = double("version", item_type: "Policy", event: "create", whodunnit: 1, created_at: 1.hour.ago, changeset: {"name" => [nil, "A new policy"], "description" => [nil, "Oh yes!"], "private" => [nil, 0], "id" => [nil, 3]})
      expect(helper.version_sentence(version)).to eq "Created policy &ldquo;A new policy&rdquo; with description &ldquo;Oh yes!&rdquo; by Matthew, about 1 hour ago"
    end

    it "change name on policy" do
      version = double("version", item_type: "Policy", event: "update", whodunnit: 1, created_at: 1.hour.ago, changeset: {"name" => ["Version A", "Version B"]})
      expect(helper.version_sentence(version)).to eq "Changed name from &ldquo;Version A&rdquo; to &ldquo;Version B&rdquo; by Matthew, about 1 hour ago"
    end

    it "change description on policy" do
      version = double("version", item_type: "Policy", event: "update", whodunnit: 1, created_at: 1.hour.ago, changeset: {"description" => ["Description A", "Description B"]})
      expect(helper.version_sentence(version)).to eq "Changed description from &ldquo;Description A&rdquo; to &ldquo;Description B&rdquo; by Matthew, about 1 hour ago"
    end

    it "change status on policy" do
      version = double("version", item_type: "Policy", event: "update", whodunnit: 1, created_at: 1.hour.ago, changeset: {"private" => [2, 0]})
      expect(helper.version_sentence(version)).to eq "Changed status to not provisional by Matthew, about 1 hour ago"
    end

    it "change everything on policy" do
      version = double("version", item_type: "Policy", event: "update", whodunnit: 1, created_at: 1.hour.ago, changeset: {"name" => ["Version A", "Version B"], "description" => ["Description A", "Description B"], "private" => [0, 2]})
      expect(helper.version_sentence(version)).to eq "Changed name from &ldquo;Version A&rdquo; to &ldquo;Version B&rdquo;, description from &ldquo;Description A&rdquo; to &ldquo;Description B&rdquo;, and status to provisional by Matthew, about 1 hour ago"
    end

    it "create vote on policy" do
      expect(Division).to receive(:find).with(5).and_return(double("division", name: "blah"))
      version = double("version", item_type: "PolicyDivision", event: "create", whodunnit: 1, created_at: 1.hour.ago, changeset: {"vote" => [nil, "aye"], "division_id" => [nil, 5]})
      expect(helper.version_sentence(version)).to eq "Added aye vote on division blah by Matthew, about 1 hour ago"
    end
  end
end

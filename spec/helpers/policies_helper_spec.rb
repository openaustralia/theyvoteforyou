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
      expect(User).to receive(:find).with(1).and_return(mock_model(User, real_name: "Matthew", id: 3))
    end

    it "create provisional policy" do
      version = double("version", item_type: "Policy", event: "create", whodunnit: 1, created_at: 1.hour.ago, changeset: {"name" => [nil, "A new policy"], "description" => [nil, "Oh yes!"], "private" => [nil, 2], "id" => [nil, 3]})
      result = helper.version_sentence(version)
      expect(result).to eq 'Created provisional policy &ldquo;A new policy&rdquo; with description &ldquo;Oh yes!&rdquo; by <a href="/users/3">Matthew</a>, about 1 hour ago'
      expect(result).to be_html_safe
    end

    it "create policy" do
      version = double("version", item_type: "Policy", event: "create", whodunnit: 1, created_at: 1.hour.ago, changeset: {"name" => [nil, "A new policy"], "description" => [nil, "Oh yes!"], "private" => [nil, 0], "id" => [nil, 3]})
      result = helper.version_sentence(version)
      expect(result).to eq 'Created policy &ldquo;A new policy&rdquo; with description &ldquo;Oh yes!&rdquo; by <a href="/users/3">Matthew</a>, about 1 hour ago'
      expect(result).to be_html_safe
    end

    it "change name on policy" do
      version = double("version", item_type: "Policy", event: "update", whodunnit: 1, created_at: 1.hour.ago, changeset: {"name" => ["Version A", "Version B"]})
      result = helper.version_sentence(version)
      expect(result).to eq 'Changed name from &ldquo;Version A&rdquo; to &ldquo;Version B&rdquo; by <a href="/users/3">Matthew</a>, about 1 hour ago'
      expect(result).to be_html_safe
    end

    it "change description on policy" do
      version = double("version", item_type: "Policy", event: "update", whodunnit: 1, created_at: 1.hour.ago, changeset: {"description" => ["Description A", "Description B"]})
      result = helper.version_sentence(version)
      expect(result).to eq 'Changed description from &ldquo;Description A&rdquo; to &ldquo;Description B&rdquo; by <a href="/users/3">Matthew</a>, about 1 hour ago'
      expect(result).to be_html_safe
    end

    it "change status on policy" do
      version = double("version", item_type: "Policy", event: "update", whodunnit: 1, created_at: 1.hour.ago, changeset: {"private" => [2, 0]})
      result = helper.version_sentence(version)
      expect(result).to eq 'Changed status to not provisional by <a href="/users/3">Matthew</a>, about 1 hour ago'
      expect(result).to be_html_safe
    end

    it "change everything on policy" do
      version = double("version", item_type: "Policy", event: "update", whodunnit: 1, created_at: 1.hour.ago, changeset: {"name" => ["Version A", "Version B"], "description" => ["Description A", "Description B"], "private" => [0, 2]})
      result = helper.version_sentence(version)
      expect(result).to eq 'Changed name from &ldquo;Version A&rdquo; to &ldquo;Version B&rdquo;, description from &ldquo;Description A&rdquo; to &ldquo;Description B&rdquo;, and status to provisional by <a href="/users/3">Matthew</a>, about 1 hour ago'
      expect(result).to be_html_safe
    end

    context "changing policy vote" do
      before :each do
        expect(Division).to receive(:find).with(5).and_return(mock_model(Division, name: "blah", date: Date.new(2001,1,1), number: 2, australian_house: "representatives"))
      end

      it "create vote on policy" do
        version = double("version", item_type: "PolicyDivision", event: "create", whodunnit: 1, created_at: 1.hour.ago, changeset: {"vote" => [nil, "aye3"], "division_id" => [nil, 5]})
        result = helper.version_sentence(version)
        expect(result).to eq 'Added <strong>aye (strong)</strong> on <a href="/divisions/representatives/2001-01-01/2">blah</a> by <a href="/users/3">Matthew</a>, about 1 hour ago'
        expect(result).to be_html_safe
      end

      it "remove vote on policy" do
        version = double("version", item_type: "PolicyDivision", event: "destroy", whodunnit: 1, created_at: 1.hour.ago, changeset: nil, reify: double("policy_division", division_id: 5, vote: "no"))
        result = helper.version_sentence(version)
        expect(result).to eq 'Removed <strong>no</strong> on <a href="/divisions/representatives/2001-01-01/2">blah</a> by <a href="/users/3">Matthew</a>, about 1 hour ago'
        expect(result).to be_html_safe
      end

      it "change vote on policy" do
        version = double("version", item_type: "PolicyDivision", event: "update", whodunnit: 1, created_at: 1.hour.ago, changeset: {"vote" => ["no", "aye"]}, reify: double("policy_division", division_id: 5))
        result = helper.version_sentence(version)
        expect(result).to eq 'Changed <strong>no</strong> to <strong>aye</strong> on <a href="/divisions/representatives/2001-01-01/2">blah</a> by <a href="/users/3">Matthew</a>, about 1 hour ago'
        expect(result).to be_html_safe
      end
    end
  end
end

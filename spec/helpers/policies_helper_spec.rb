# frozen_string_literal: true

require "spec_helper"

describe PoliciesHelper, type: :helper do
  before do
    User.delete_all
    Policy.delete_all
  end

  describe ".version_sentence" do
    before do
      allow(Policy).to receive(:find).with(3).and_return(mock_model(Policy, id: 3, name: "chickens"))
    end

    context "with create provisional policy" do
      let(:version) { instance_double("version", item_type: "Policy", event: "create", changeset: { "name" => [nil, "A new policy"], "description" => [nil, "Oh yes!"], "private" => [nil, 2], "id" => [nil, 3] }) }

      it { expect(helper.version_sentence(version)).to eq '<p class="change-action">Created draft policy “A new policy” with description “Oh yes!”.</p>' }
      it { expect(helper.version_sentence_text(version)).to eq "Created draft policy “A new policy” with description “Oh yes!”." }
      it { expect(helper.version_sentence(version)).to be_html_safe }
    end

    context "with create policy" do
      let(:version) { instance_double("version", item_type: "Policy", event: "create", changeset: { "name" => [nil, "A new policy"], "description" => [nil, "Oh yes!"], "private" => [nil, 0], "id" => [nil, 3] }) }

      it { expect(helper.version_sentence(version)).to eq '<p class="change-action">Created policy “A new policy” with description “Oh yes!”.</p>' }
      it { expect(helper.version_sentence_text(version)).to eq "Created policy “A new policy” with description “Oh yes!”." }
      it { expect(helper.version_sentence(version)).to be_html_safe }
    end

    context "with change name on policy" do
      let(:version) { instance_double("version", item_type: "Policy", event: "update", whodunnit: 1, created_at: 1.hour.ago, changeset: { "name" => ["Version A", "Version B"] }, reify: mock_model(Policy, id: 3, name: "Version A")) }

      it { expect(helper.version_sentence(version)).to eq '<p class="change-action">Name changed from “Version A” to “Version B”.</p>' }
      it { expect(helper.version_sentence_text(version)).to eq "* Changed name from “Version A” to “Version B”." }
      it { expect(helper.version_sentence(version)).to be_html_safe }
    end

    context "with change description on policy" do
      let(:version) { instance_double("version", item_type: "Policy", event: "update", whodunnit: 1, created_at: 1.hour.ago, changeset: { "description" => ["Description A", "Description B"] }, reify: mock_model(Policy, id: 3, name: "Version A")) }

      it { expect(helper.version_sentence(version)).to eq '<p class="change-action">Description changed from “Description A” to “Description B”.</p>' }
      it { expect(helper.version_sentence_text(version)).to eq "* Changed description from “Description A” to “Description B”." }
      it { expect(helper.version_sentence(version)).to be_html_safe }
    end

    context "with change status on policy" do
      let(:version) { instance_double("version", item_type: "Policy", event: "update", whodunnit: 1, created_at: 1.hour.ago, changeset: { "private" => [2, 0] }, reify: mock_model(Policy, id: 3, name: "Version A")) }

      it { expect(helper.version_sentence(version)).to eq '<p class="change-action">Changed status to not draft.</p>' }
      it { expect(helper.version_sentence_text(version)).to eq "* Changed status to not draft." }
      it { expect(helper.version_sentence(version)).to be_html_safe }
    end

    context "with change status on policy using new naming" do
      let(:version) { instance_double("version", item_type: "Policy", event: "update", whodunnit: 1, created_at: 1.hour.ago, changeset: { "private" => %w[provisional published] }, reify: mock_model(Policy, id: 3, name: "Version A")) }

      it { expect(helper.version_sentence(version)).to eq '<p class="change-action">Changed status to not draft.</p>' }
      it { expect(helper.version_sentence_text(version)).to eq "* Changed status to not draft." }
      it { expect(helper.version_sentence(version)).to be_html_safe }
    end

    context "with change everything on policy" do
      let(:version) { instance_double("version", item_type: "Policy", event: "update", whodunnit: 1, created_at: 1.hour.ago, changeset: { "name" => ["Version A", "Version B"], "description" => ["Description A", "Description B"], "private" => [0, 2] }, reify: mock_model(Policy, id: 3, name: "Version A")) }

      it { expect(helper.version_sentence(version)).to eq '<p class="change-action">Name changed from “Version A” to “Version B”.</p><p class="change-action">Description changed from “Description A” to “Description B”.</p><p class="change-action">Changed status to draft.</p>' }
      it { expect(helper.version_sentence_text(version)).to eq "* Changed name from “Version A” to “Version B”.\n* Changed description from “Description A” to “Description B”.\n* Changed status to draft." }
      it { expect(helper.version_sentence(version)).to be_html_safe }
    end

    context "with changing policy vote" do
      before do
        allow(Division).to receive(:find).with(5).and_return(stub_model(Division, name: "blah", date: Date.new(2001, 1, 1), number: 2, house: "representatives"))
      end

      context "with create vote on policy" do
        let(:version) { instance_double("version", item_type: "PolicyDivision", event: "create", whodunnit: 1, created_at: 1.hour.ago, changeset: { "vote" => [nil, "aye3"], "division_id" => [nil, 5] }, policy_id: 3) }

        it { expect(helper.version_sentence(version)).to eq '<p class="change-action">Added division <em><a href="http://test.host/divisions/representatives/2001-01-01/2">blah</a></em>. Policy vote set to <span class="division-policy-statement-vote voted-aye">Yes (strong)</span>.</p>' }
        it { expect(helper.version_sentence_text(version)).to eq "Added division blah. Policy vote set to Yes (strong).\nhttp://test.host/divisions/representatives/2001-01-01/2" }
        it { expect(helper.version_sentence(version)).to be_html_safe }
      end

      context "with remove vote on policy" do
        let(:version) { instance_double("version", item_type: "PolicyDivision", event: "destroy", whodunnit: 1, created_at: 1.hour.ago, changeset: nil, reify: instance_double("policy_division", division_id: 5, vote: "no"), policy_id: 3) }

        it { expect(helper.version_sentence(version)).to eq '<p class="change-action">Removed division <em><a href="http://test.host/divisions/representatives/2001-01-01/2">blah</a></em>. Policy vote was <span class="division-policy-statement-vote voted-no">No</span>.</p>' }
        it { expect(helper.version_sentence_text(version)).to eq "Removed division blah. Policy vote was No.\nhttp://test.host/divisions/representatives/2001-01-01/2" }
        it { expect(helper.version_sentence(version)).to be_html_safe }
      end

      context "with change vote on policy" do
        let(:version) { instance_double("version", item_type: "PolicyDivision", event: "update", whodunnit: 1, created_at: 1.hour.ago, changeset: { "vote" => %w[no aye] }, reify: instance_double("policy_division", division_id: 5), policy_id: 3) }

        it { expect(helper.version_sentence(version)).to eq '<p class="change-action">Changed vote from <span class="division-policy-statement-vote voted-no">No</span> to <span class="division-policy-statement-vote voted-aye">Yes</span> on division <em><a href="http://test.host/divisions/representatives/2001-01-01/2">blah</a></em>.</p>' }
        it { expect(helper.version_sentence_text(version)).to eq "Changed vote from No to Yes on division blah.\nhttp://test.host/divisions/representatives/2001-01-01/2" }
        it { expect(helper.version_sentence(version)).to be_html_safe }
      end
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

describe DivisionsController, type: :request do
  include HTMLCompareHelper

  include_context "with fixtures"

  describe "#show" do
    it do
      division_representatives_2006_12_06_3
      policy2
      member_john_howard
      compare_static("/divisions/representatives/2006-12-06/3")
    end

    it do
      division_representatives_2013_03_14_1
      policy1
      member_tony_abbott
      member_john_alexander
      compare_static("/divisions/representatives/2013-03-14/1")
    end

    it do
      division_senate_2013_03_14_1
      policy2
      policy3
      compare_static("/divisions/senate/2013-03-14/1")
    end
  end

  describe "#show, AI policy suggestions" do
    let(:kimi) { "moonshotai.kimi-k2.5" }
    let(:deepseek) { "deepseek.v3.2" }
    let(:claude) { "au.anthropic.claude-haiku-4-5-20251001-v1:0" }
    let(:division) { division_representatives_2006_12_06_3 }

    before do
      division
      policy1
    end

    it "is hidden when no model has classified the division yet, even for staff" do
      login_as(user)
      get "/divisions/representatives/2006-12-06/3"
      expect(response.body).not_to include("ai-policy-suggestions")
    end

    it "is hidden from non-staff even when suggestions exist" do
      create(:ai_policy_suggestion, division: division, policy: policy1, model: kimi)
      get "/divisions/representatives/2006-12-06/3"
      expect(response.body).not_to include("ai-policy-suggestions")
    end

    it "shows each model's proposal to staff, flagging agreement between models" do
      login_as(user)
      create(:ai_policy_suggestion, division: division, policy: policy1, model: kimi, direction: "for")
      create(:ai_policy_suggestion, division: division, policy: policy1, model: deepseek, direction: "for")
      create(:ai_policy_suggestion, division: division, policy: policy1, model: claude, direction: "against")

      get "/divisions/representatives/2006-12-06/3"

      expect(response.body).to include("Kimi K2.5")
      expect(response.body).to include("DeepSeek V3.2")
      expect(response.body).to include("Claude Haiku 4.5")
      expect(response.body.scan("models agree").size).to eq(2)
    end

    it "labels the section so staff know to click it to review the suggestions" do
      login_as(user)
      create(:ai_policy_suggestion, division: division, policy: policy1, model: kimi)

      get "/divisions/representatives/2006-12-06/3"

      expect(response.body).to include("We have AI suggestions")
      expect(response.body).to include("review")
    end

    it "links a suggestion's summary to the policy it matched" do
      login_as(user)
      create(:ai_policy_suggestion, division: division, policy: policy1, model: kimi, direction: "for")

      get "/divisions/representatives/2006-12-06/3"

      expect(response.body).to include(%(href="#{policy_path(policy1)}"))
    end

    it "shows a suggestion as already linked when the division's already connected to that policy" do
      login_as(user)
      create(:policy_division, division: division, policy: policy1, vote: "aye")
      create(:ai_policy_suggestion, division: division, policy: policy1, model: kimi, direction: "for")

      get "/divisions/representatives/2006-12-06/3"

      expect(response.body).to include("Already linked")
    end

    it "doesn't call an existing match a new policy when the matched policy has been deleted" do
      login_as(user)
      create(:ai_policy_suggestion, division: division, policy: policy1, model: kimi,
                                    match: "existing", direction: "for")

      policy1.destroy!
      get "/divisions/representatives/2006-12-06/3"

      expect(response.body).to include("For a policy that has since been deleted")
      expect(response.body).not_to include("new policy:")
    end

    it "styles a suggestion with no match/direction as an error, rather than a misleading new-policy line" do
      login_as(user)
      create(:ai_policy_suggestion, division: division, policy: policy1, model: kimi,
                                    match: nil, direction: nil, error: nil)

      get "/divisions/representatives/2006-12-06/3"

      expect(response.body).to include("<p class='text-danger'>Error: model response was missing match/direction</p>")
      expect(response.body).not_to include("new policy:")
    end

    it "offers staff a quick link to the policy when all three models agree" do
      login_as(user)
      create(:ai_policy_suggestion, division: division, policy: policy1, model: kimi, direction: "for")
      create(:ai_policy_suggestion, division: division, policy: policy1, model: deepseek, direction: "for")
      create(:ai_policy_suggestion, division: division, policy: policy1, model: claude, direction: "for")

      get "/divisions/representatives/2006-12-06/3"

      expect(response.body).to include("Link this division to marriage equality")
    end

    it "doesn't offer a quick link when only two of the three models agree" do
      login_as(user)
      create(:ai_policy_suggestion, division: division, policy: policy1, model: kimi, direction: "for")
      create(:ai_policy_suggestion, division: division, policy: policy1, model: deepseek, direction: "for")
      create(:ai_policy_suggestion, division: division, policy: policy1, model: claude, direction: "against")

      get "/divisions/representatives/2006-12-06/3"

      expect(response.body).not_to include("Link this division to")
    end

    it "doesn't offer a quick link when the division's already linked to that policy" do
      login_as(user)
      create(:policy_division, division: division, policy: policy1, vote: "aye")
      create(:ai_policy_suggestion, division: division, policy: policy1, model: kimi, direction: "for")
      create(:ai_policy_suggestion, division: division, policy: policy1, model: deepseek, direction: "for")
      create(:ai_policy_suggestion, division: division, policy: policy1, model: claude, direction: "for")

      get "/divisions/representatives/2006-12-06/3"

      expect(response.body).not_to include("Link this division to")
    end

    it "actually links the division to the policy when the quick link button is submitted" do
      login_as(user)
      create(:ai_policy_suggestion, division: division, policy: policy1, model: kimi, direction: "for")
      create(:ai_policy_suggestion, division: division, policy: policy1, model: deepseek, direction: "for")
      create(:ai_policy_suggestion, division: division, policy: policy1, model: claude, direction: "for")

      params = { policy_division: { policy_id: policy1.id, vote: "aye" } }
      post "/divisions/representatives/2006-12-06/3/policies/create", params: params

      expect(division.policy_divisions.find_by(policy: policy1)&.vote).to eq "aye"
    end
  end

  describe "#index" do
    before do
      division_representatives_2006_12_06_3
      division_senate_2009_11_25_8
      division_senate_2009_11_30_8
      division_senate_2009_12_30_8
      division_representatives_2013_03_14_1
      division_senate_2013_03_14_1
    end

    it { compare_static("/divisions/all/2007") }
    it { compare_static("/divisions/all/2004") }
    it { compare_static("/divisions/all") }
    it { compare_static("/divisions/representatives") }
    it { compare_static("/divisions/representatives/2007") }
    it { compare_static("/divisions/representatives/2004") }
    it { compare_static("/divisions/senate") }
    it { compare_static("/divisions/senate/2007") }
    it { compare_static("/divisions/senate/2004") }

    it { compare_static("/divisions/all/2007?sort=subject") }
    it { compare_static("/divisions/all/2004?sort=subject") }
    it { compare_static("/divisions/all?sort=subject") }
    it { compare_static("/divisions/representatives?sort=subject") }
    it { compare_static("/divisions/representatives/2007?sort=subject") }
    it { compare_static("/divisions/representatives/2004?sort=subject") }
    it { compare_static("/divisions/senate?sort=subject") }
    it { compare_static("/divisions/senate/2007?sort=subject") }
    it { compare_static("/divisions/senate/2004?sort=subject") }

    it { compare_static("/divisions/all/2007?sort=rebellions") }
    it { compare_static("/divisions/all/2004?sort=rebellions") }
    it { compare_static("/divisions/all?sort=rebellions") }
    it { compare_static("/divisions/representatives?sort=rebellions") }
    it { compare_static("/divisions/representatives/2007?sort=rebellions") }
    it { compare_static("/divisions/representatives/2004?sort=rebellions") }
    it { compare_static("/divisions/senate?sort=rebellions") }
    it { compare_static("/divisions/senate/2007?sort=rebellions") }
    it { compare_static("/divisions/senate/2004?sort=rebellions") }

    it { compare_static("/divisions/all/2007?sort=turnout") }
    it { compare_static("/divisions/all/2004?sort=turnout") }
    it { compare_static("/divisions/all?sort=turnout") }
    it { compare_static("/divisions/representatives?sort=turnout") }
    it { compare_static("/divisions/representatives/2007?sort=turnout") }
    it { compare_static("/divisions/representatives/2004?sort=turnout") }
    it { compare_static("/divisions/senate?sort=turnout") }
    it { compare_static("/divisions/senate/2007?sort=turnout") }
    it { compare_static("/divisions/senate/2004?sort=turnout") }
  end

  context "when logged in" do
    before do
      login_as(user)
    end

    describe "#show_policies" do
      before do
        policy1
        policy2
        policy3
      end

      it do
        division_representatives_2006_12_06_3
        compare_static("/divisions/representatives/2006-12-06/3/policies")
      end

      it do
        division_representatives_2013_03_14_1
        compare_static("/divisions/representatives/2013-03-14/1/policies")
      end

      it do
        division_senate_2009_11_25_8
        compare_static("/divisions/senate/2009-11-25/8/policies")
      end

      it do
        division_senate_2013_03_14_1
        compare_static("/divisions/senate/2013-03-14/1/policies")
      end
    end

    describe "#edit" do
      it do
        division_senate_2009_11_25_8
        compare_static "/divisions/senate/2009-11-25/8/edit"
      end

      it do
        division_representatives_2013_03_14_1
        compare_static "/divisions/representatives/2013-03-14/1/edit"
      end
    end

    describe "#update" do
      it do
        division_senate_2009_11_25_8
        compare_static "/divisions/senate/2009-11-25/8", form_params: { submit: "Save", newtitle: "A lovely new title", newdescription: "And a great new description" }
      end
    end

    describe "#create_policy_division, #update_policy_division, #destroy_policy_division" do
      # Regression coverage for a bug where the after_action recalculating PolicyPersonDistance
      # records called Pundit's own policy(record) helper with no arguments (a bare `policy`, meant
      # to be the connection's actual Policy) - raising ArgumentError and crashing every one of
      # these three actions, despite the underlying save/update/destroy having already succeeded.
      it "connects a division to a policy without erroring" do
        division = division_representatives_2006_12_06_3
        policy1

        post "/divisions/representatives/2006-12-06/3/policies/create", params: { policy_division: { policy_id: policy1.id, vote: "aye" } }

        expect(response).to redirect_to("/divisions/representatives/2006-12-06/3/policies")
        expect(division.policy_divisions.find_by(policy: policy1)&.vote).to eq "aye"
      end

      it "updates an existing connection without erroring" do
        division = division_representatives_2006_12_06_3
        policy1
        create(:policy_division, division: division, policy: policy1, vote: "aye")

        patch "/divisions/representatives/2006-12-06/3/policies/#{policy1.id}", params: { policy_division: { vote: "no" } }

        expect(response).to redirect_to("/divisions/representatives/2006-12-06/3/policies")
        expect(division.policy_divisions.find_by(policy: policy1).vote).to eq "no"
      end

      it "removes an existing connection without erroring" do
        division = division_representatives_2006_12_06_3
        policy1
        create(:policy_division, division: division, policy: policy1, vote: "aye")

        delete "/divisions/representatives/2006-12-06/3/policies/#{policy1.id}/delete"

        expect(response).to redirect_to("/divisions/representatives/2006-12-06/3/policies")
        expect(division.policy_divisions.find_by(policy: policy1)).to be_nil
      end
    end
  end
end

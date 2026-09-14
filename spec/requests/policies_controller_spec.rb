# frozen_string_literal: true

require "spec_helper"
# Compare results of rendering pages via rails and via the old php app

describe PoliciesController, type: :request do
  include HTMLCompareHelper

  include_context "with fixtures"

  before do
    policy1
    policy2
    member_tony_abbott
    member_kevin_rudd
    member_john_alexander
    policy1_tony_abbott
    policy1_kevin_rudd
    policy1_john_alexander
    # To workaround paper trail and fixtures problems we're deleting the static
    # fixtures data and recreating here in such a way that the versions in paper
    # trail are setup the way we want
    Policy.delete_all
    PaperTrail::Version.delete_all

    PaperTrail.request.whodunnit = user.id
    Timecop.freeze(25.hours.ago) do
      create(:policy, id: 1, name: "marriage equality", description: "access to marriage should be equal")
      create(:policy, id: 2, name: "offshore processing", description: "refugees arrving by boat should be processed offshore")
    end
  end

  it "#index" do
    compare_static("/policies")
  end

  describe "#show" do
    it { compare_static("/policies/1") }
    it { compare_static("/policies/2") }

    it "shows the edit is by an unknown user instead of erroring, when that user's since been deleted" do
      editor = create(:confirmed_user)
      PaperTrail.request.whodunnit = editor.id
      Policy.find(1).update!(description: "a further edit, by someone who won't stick around")
      editor.destroy!

      get "/policies/1"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Unknown user")
    end
  end
end

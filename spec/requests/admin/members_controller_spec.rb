# frozen_string_literal: true

require "spec_helper"

describe Admin::MembersController, type: :request do
  include Devise::Test::IntegrationHelpers

  let!(:member) { create(:member, first_name: "Examplea", last_name: "Senatorson", house: "senate") }

  context "when signed in as a user who is not an admin" do
    before { sign_in create(:confirmed_user) }

    it "is forbidden" do
      get admin_members_path
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "when signed in as an admin" do
    before { sign_in create(:confirmed_user, admin: true) }

    it "lists members" do
      get admin_members_path
      expect(response.body).to include("Senatorson")
    end

    it "has no row menu, as members can't be edited or deleted" do
      get admin_members_path
      expect(response.parsed_body.at_css("details.row-menu")).to be_nil
    end

    it "shows a member" do
      get admin_member_path(member)
      expect(response).to have_http_status(:ok)
    end

    it "has no way to edit or delete a member" do
      expect { Rails.application.routes.recognize_path("/admin/members/#{member.id}/edit") }
        .to raise_error(ActionController::RoutingError)
    end
  end
end

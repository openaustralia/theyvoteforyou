# frozen_string_literal: true

require "spec_helper"

describe "Admin announcements", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:admin) { create(:confirmed_user, admin: true) }

  it "sends a logged-out visitor to log in" do
    get admin_announcements_path
    expect(response).to redirect_to(new_user_session_path)
  end

  it "refuses a user who is not an admin" do
    sign_in create(:confirmed_user)
    get admin_announcements_path
    expect(response).to have_http_status(:forbidden)
  end

  context "when signed in as an admin" do
    before { sign_in admin }

    it "lists announcements" do
      create(:announcement, body: "Listed notice")
      get admin_announcements_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Listed notice")
    end

    it "creates an announcement" do
      expect do
        post admin_announcements_path, params: { announcement: { body: "New notice", published: "1" } }
      end.to change(Announcement, :count).by(1)
      expect(Announcement.last).to have_attributes(body: "New notice", published: true)
    end

    it "updates an announcement" do
      announcement = create(:announcement, body: "Before")
      patch admin_announcement_path(announcement), params: { announcement: { body: "After" } }
      expect(announcement.reload.body).to eq "After"
    end

    it "deletes an announcement" do
      announcement = create(:announcement)
      expect { delete admin_announcement_path(announcement) }.to change(Announcement, :count).by(-1)
    end
  end
end

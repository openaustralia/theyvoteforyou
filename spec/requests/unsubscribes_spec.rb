# frozen_string_literal: true

require "spec_helper"

RSpec.describe "One-click unsubscribe", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:confirmed_user) }
  let(:other_user) { create(:confirmed_user) }
  let(:policy) { create(:policy) }
  let(:division) { create(:division) }
  let(:token) { user.unsubscribe_token }

  before do
    policy.watches.create!(user: user)
    Watch.create!(user: user, watchable: division)
    policy.watches.create!(user: other_user)
  end

  describe "POST /unsubscribe/:token" do
    it "removes every policy and division subscription the person has, and only theirs" do
      post "/unsubscribe/#{token}"

      expect(response).to have_http_status(:ok)
      expect(user.watches.count).to eq(0)
      expect(other_user.watches.count).to eq(1)
    end

    it "confirms what happened and links back to the policies" do
      post "/unsubscribe/#{token}"

      expect(response.body).to include("You will no longer get emails", "2 subscriptions", policies_path)
    end

    it "needs no login and no form token, as a mail client sends neither" do
      ActionController::Base.allow_forgery_protection = true
      post "/unsubscribe/#{token}", headers: { "CONTENT_TYPE" => "application/x-www-form-urlencoded" },
                                    params: "List-Unsubscribe=One-Click"

      expect(user.watches.count).to eq(0)
    ensure
      ActionController::Base.allow_forgery_protection = false
    end

    it "doesn't keep the token in the session as the last page visited" do
      get "/unsubscribe/#{token}"

      expect(session[:previous_url]).to be_nil
    end

    it "is harmless to repeat" do
      2.times { post "/unsubscribe/#{token}" }

      expect(response).to have_http_status(:ok)
      expect(other_user.watches.count).to eq(1)
    end

    it "refuses a tampered token" do
      post "/unsubscribe/#{token}x"

      expect(response).to have_http_status(:not_found)
      expect(user.watches.count).to eq(2)
    end

    it "refuses a token made for another purpose" do
      post "/unsubscribe/#{user.signed_id(purpose: :something_else)}"

      expect(response).to have_http_status(:not_found)
      expect(user.watches.count).to eq(2)
    end

    it "refuses a token for no one" do
      post "/unsubscribe/nonsense"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /unsubscribe/:token" do
    it "asks for confirmation without changing anything, and links back to the policies" do
      get "/unsubscribe/#{token}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Unsubscribe from all", policies_path)
      expect(user.watches.count).to eq(2)
    end

    it "refuses a tampered token" do
      get "/unsubscribe/#{token}x"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "the existing unsubscribe on a policy page" do
    it "still removes just that policy's subscription" do
      sign_in user

      post "/policies/#{policy.id}/watch"

      expect(user.watches.pluck(:watchable_type)).to eq(["Division"])
    end
  end
end

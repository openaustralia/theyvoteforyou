# frozen_string_literal: true

require "spec_helper"

describe Admin::ApiUsagesController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:admin) { create(:confirmed_user, admin: true) }
  let(:api_user) { create(:confirmed_user, name: "Busy API user") }

  before do
    DailyApiUsage.create!(user: api_user, date: Time.current.utc.to_date, count: 1234)
    sign_in admin
  end

  it "lists the busiest API users" do
    get "/admin/api_usages"
    expect(response.body).to include("Busy API user", "1,234")
  end

  it "only shows usage within the period" do
    DailyApiUsage.create!(user: create(:confirmed_user, name: "Old API user"), date: 10.days.ago.utc.to_date, count: 5)
    get "/admin/api_usages", params: { period: 7 }
    expect(response.body).not_to include("Old API user")
  end

  it "is only for admins" do
    sign_in create(:confirmed_user)
    get "/admin/api_usages"
    expect(response).to have_http_status(:forbidden)
  end
end

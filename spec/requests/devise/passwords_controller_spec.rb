# frozen_string_literal: true

require "spec_helper"

describe Devise::PasswordsController, type: :request do
  describe "GET /users/password/new" do
    it "renders the forgotten password form" do
      get "/users/password/new"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /users/password" do
    it "re-renders the form with validation errors when the email is blank" do
      post "/users/password", params: { user: { email: "" } }
      expect(response.body).to include("Email can&#39;t be blank")
    end
  end

  describe "GET /users/password/edit" do
    it "renders the change password form" do
      get "/users/password/edit", params: { reset_password_token: "abc123" }
      expect(response).to have_http_status(:ok)
    end
  end
end

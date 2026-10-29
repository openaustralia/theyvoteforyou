# frozen_string_literal: true

require "spec_helper"

describe Admin::IngestsController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:admin) { create(:confirmed_user, admin: true) }
  let(:zip_file) { Rack::Test::UploadedFile.new(StringIO.new("not read yet"), "application/zip", original_filename: "drafts.zip") }

  context "when signed in as a user who is not an admin" do
    before { sign_in create(:confirmed_user) }

    it "is forbidden" do
      get new_admin_ingest_path
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "when signed in as an admin" do
    before { sign_in admin }

    it "shows the upload form" do
      get new_admin_ingest_path(kind: "division-summary")
      expect(response.body).to include("Upload AI summary drafts", "type=\"file\"")

      # Dropping a file needs JavaScript, which request specs don't run, so this only checks the zone is there
      # and that the plain file input inside it still works without the script.
      zone = response.parsed_body.at_css("#ingest-dropzone")
      expect(zone.text).to include("Drop a zip file here")
      expect(zone.at_css("input[type=file][name=file][accept='.zip,application/zip']")).to be_present
    end

    it "stores the zip against a queued upload from the admin" do
      expect { post admin_ingests_path, params: { kind: "division-summary", file: zip_file } }
        .to change(Ingest, :count).by(1)

      ingest = Ingest.last
      expect(ingest).to have_attributes(status: "queued", user: admin, original_filename: "drafts.zip")
      expect(File.read(ingest.file_path)).to eq("not read yet")
      expect(response).to redirect_to(admin_ingest_path(ingest))
    end

    it "refuses a file that is not a zip" do
      file = Rack::Test::UploadedFile.new(StringIO.new("hello"), "text/plain", original_filename: "notes.txt")
      expect { post admin_ingests_path, params: { kind: "division-summary", file: file } }.not_to change(Ingest, :count)
      expect(response).to redirect_to(new_admin_ingest_path(kind: "division-summary"))
      expect(flash[:alert]).to eq("The file must be a .zip")
    end

    it "refuses an upload with no file" do
      expect { post admin_ingests_path, params: { kind: "division-summary" } }.not_to change(Ingest, :count)
      expect(response).to redirect_to(new_admin_ingest_path(kind: "division-summary"))
      expect(flash[:alert]).to eq("Choose a zip file to upload")
    end

    it "is called Uploaded ingests in the menu and on its page" do
      get admin_ingests_path
      expect(response.parsed_body.at_css("nav.navigation a[href='#{admin_ingests_path}']").text.strip).to eq("Uploaded ingests")
      expect(response.parsed_body.at_css("h1").text.strip).to eq("Uploaded ingests")
    end

    it "lists uploads" do
      Ingest.create!(kind: "division-summary", user: admin, original_filename: "drafts-example.zip")
      get admin_ingests_path
      expect(response.body).to include("drafts-example.zip")
    end
  end
end

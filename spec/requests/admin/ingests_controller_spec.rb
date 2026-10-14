# frozen_string_literal: true

require "spec_helper"

describe Admin::IngestsController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:admin) { create(:confirmed_user, admin: true) }
  let!(:division) { create(:division, house: "senate", date: Date.new(2026, 9, 17), number: 5) }
  let(:zip_files) do
    { "local.Example/senate/2026-09-17/senate_2026-09-17_5.md" => "# A title\n\nA description." }
  end

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
    end

    it "stores the zip, runs the job and saves the drafts against the division" do
      expect { post admin_ingests_path, params: { kind: "division-summary", file: uploaded_zip(zip_files) } }
        .to change(Ingest, :count).by(1)

      ingest = Ingest.last
      expect(ingest).to have_attributes(status: "done", records_saved: 1, user: admin, original_filename: /\.zip\z/)
      expect(File).to exist(ingest.file_path)
      expect(division.ai_division_summaries.sole).to have_attributes(title: "A title", ingest: ingest)
    end

    it "records why a bad upload failed" do
      post admin_ingests_path, params: { kind: "division-summary",
                                         file: uploaded_zip("local.Example/senate_2026-09-17_99.md" => "# T\n\nD") }

      expect(Ingest.last).to have_attributes(status: "failed", error: /senate_2026-09-17_99.md/)
      expect(AiDivisionSummary.count).to eq(0)
    end

    it "refuses a file that is not a zip" do
      file = Rack::Test::UploadedFile.new(StringIO.new("hello"), "text/plain", original_filename: "notes.txt")
      expect { post admin_ingests_path, params: { kind: "division-summary", file: file } }.not_to change(Ingest, :count)
    end

    it "refuses an upload with no file" do
      expect { post admin_ingests_path, params: { kind: "division-summary" } }.not_to change(Ingest, :count)
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

    describe "deleting the drafts from one upload" do
      let(:ingest) { Ingest.create!(kind: "division-summary", user: admin, status: "done") }
      let(:other_ingest) { Ingest.create!(kind: "division-summary", user: admin, status: "done") }

      before do
        AiDivisionSummary.create!(division: division, model: "a", title: "T", description: "D", ingest: ingest)
        AiDivisionSummary.create!(division: division, model: "b", title: "T", description: "D", ingest: other_ingest)
        AiDivisionSummary.create!(division: division, model: "c", title: "T", description: "D")
      end

      it "offers the button on the upload's page" do
        get admin_ingest_path(ingest)
        expect(response.body).to include("Delete 1 draft from this upload")
      end

      it "deletes only the drafts that came from that upload, and keeps the upload" do
        delete delete_summaries_admin_ingest_path(ingest)

        expect(division.ai_division_summaries.pluck(:model)).to contain_exactly("b", "c")
        expect(Ingest.exists?(ingest.id)).to be(true)
      end
    end

    it "has an Upload summaries button on the list of divisions" do
      get admin_divisions_path
      button = response.parsed_body.at_css("a.button[href='#{new_admin_ingest_path(kind: 'division-summary')}']")
      expect(button.text).to eq("Upload summaries")
    end

    it "links to the upload page from a division" do
      get admin_division_path(division)
      expect(response.body).to include("Upload AI summary drafts", new_admin_ingest_path(kind: "division-summary"))
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

describe Admin::DivisionsController, type: :request do
  include Devise::Test::IntegrationHelpers
  include PathHelper

  let(:division) { create(:division, name: "Bills - Test Bill 2026; First Reading") }

  context "when signed out" do
    it "asks for a sign in" do
      get admin_divisions_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context "when signed in as a user who is not an admin" do
    before { sign_in create(:confirmed_user) }

    it "is forbidden" do
      get admin_divisions_path
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "when signed in as an admin" do
    before { sign_in create(:confirmed_user, admin: true) }

    it "lists divisions" do
      division
      get admin_divisions_path
      expect(response.body).to include("Test Bill 2026")
    end

    it "shows a division" do
      get admin_division_path(division)
      expect(response).to have_http_status(:ok)
    end

    it "links to the division on the public site" do
      get admin_division_path(division)
      expect(response.body).to include(%(href="#{division_path_simple(division)}"))
    end

    it "links to the edit form, where an editor picks an AI draft to start from" do
      get admin_division_path(division)
      expect(response.body).to include(%(href="#{edit_division_path_simple(division)}"))
    end

    it "shows the AI policy drafts for a division" do
      AiPolicySuggestion.create!(division: division, model: "example.model", match: "new",
                                 direction: "for", proposed_policy_name: "A proposed policy name")
      get admin_division_path(division)
      expect(response.body).to include("example.model", "A proposed policy name")
    end

    describe "summary status" do
      it "says a division with a human written summary is summarised" do
        create(:wiki_motion, division: division)
        get admin_division_path(division)
        expect(response.body).to include("Summarised")
      end

      it "says when there is no summary and no draft" do
        get admin_division_path(division)
        expect(response.body).to include("Not summarised yet")
        expect(response.body).not_to include("waiting for review")
      end

      it "counts the AI drafts waiting for review, but not ones that errored" do
        AiDivisionSummary.create!(division: division, model: "a", title: "T", description: "D")
        AiDivisionSummary.create!(division: division, model: "b", error: "Bedrock failed")
        get admin_division_path(division)
        expect(response.body).to include("Not summarised yet", "1 AI draft waiting for review")
      end

      it "shows the status in the list too" do
        AiDivisionSummary.create!(division: division, model: "a", title: "T", description: "D")
        get admin_divisions_path
        expect(response.body).to include("1 AI draft waiting for review")
      end
    end

    it "puts Summarise, Edit and Delete in a menu on each row of the list" do
      division
      get admin_divisions_path

      menu = response.parsed_body.at_css("details.row-menu")
      expect(menu.text).to include("Edit", "Delete")
      expect(menu.css("a").to_h { |link| [link.text, link[:href]] })
        .to eq("Summarise" => edit_division_path_simple(division), "Edit" => edit_admin_division_path(division))
    end

    describe "filtering the list by house" do
      before do
        create(:division, house: "senate", name: "A senate division", date: Date.new(2026, 9, 1))
        create(:division, house: "representatives", name: "A house division", date: Date.new(2026, 9, 2))
      end

      it "offers links to each house, and to each summary state" do
        get admin_divisions_path
        links = response.parsed_body.css("nav a").to_h { |link| [link.text, link[:href]] }
        expect(links).to include("Representatives" => "/admin/divisions?search=representatives%3A",
                                 "Senate" => "/admin/divisions?search=senate%3A",
                                 "Summarised" => "/admin/divisions?search=summarised%3A",
                                 "Not summarised yet" => "/admin/divisions?search=unsummarised%3A",
                                 "Not summarised, with an AI draft waiting" => "/admin/divisions?search=drafts_waiting%3A")
      end

      it "keeps the house when a summary filter is chosen, and the other way round" do
        get admin_divisions_path(search: "senate:")
        hrefs = response.parsed_body.css("nav a").pluck(:href)
        expect(hrefs).to include("/admin/divisions?search=senate%3A+summarised%3A")

        get admin_divisions_path(search: "summarised:")
        hrefs = response.parsed_body.css("nav a").pluck(:href)
        expect(hrefs).to include("/admin/divisions?search=representatives%3A+summarised%3A")
      end

      it "shows only senate divisions" do
        get admin_divisions_path(search: "senate:")
        expect(response.body).to include("A senate division")
        expect(response.body).not_to include("A house division")
      end

      it "shows only representatives divisions" do
        get admin_divisions_path(search: "representatives:")
        expect(response.body).to include("A house division")
        expect(response.body).not_to include("A senate division")
      end

      describe "by summary" do
        let!(:summarised) { create(:division, name: "Has a summary", date: Date.new(2026, 9, 3)) }
        let!(:with_draft) { create(:division, name: "Has only a draft", date: Date.new(2026, 9, 4)) }
        let!(:with_bad_draft) { create(:division, name: "Has only a failed draft", date: Date.new(2026, 9, 5)) }

        before do
          create(:wiki_motion, division: summarised, title: "Has a summary")
          AiDivisionSummary.create!(division: summarised, model: "a", title: "T", description: "D")
          AiDivisionSummary.create!(division: with_draft, model: "a", title: "T", description: "D")
          AiDivisionSummary.create!(division: with_bad_draft, model: "a", error: "Bedrock failed")
        end

        def listed(search)
          get admin_divisions_path(search: search)
          response.parsed_body.css("td.cell-data--string a").map(&:text).map(&:strip).grep(/\AHas /)
        end

        it "shows only divisions that have a summary" do
          expect(listed("summarised:")).to eq(["Has a summary"])
        end

        it "shows only divisions that have no summary yet" do
          expect(listed("unsummarised:")).to contain_exactly("Has only a draft", "Has only a failed draft")
        end

        it "shows only divisions with no summary but an AI draft to pick from, ignoring drafts that errored" do
          expect(listed("drafts_waiting:")).to eq(["Has only a draft"])
        end

        it "combines with the house filter" do
          expect(listed("senate: drafts_waiting:")).to be_empty
          expect(listed("representatives: drafts_waiting:")).to eq(["Has only a draft"])
        end
      end

      it "finds divisions by name from the search box" do
        get admin_divisions_path(search: "senate division")
        expect(response.body).to include("A senate division")
        expect(response.body).not_to include("A house division")
      end

      it "shows both with no filter" do
        get admin_divisions_path
        expect(response.body).to include("A senate division", "A house division")
      end
    end

    describe "the page Summarise leads to" do
      before do
        create(:wiki_motion, division: division, title: "Existing human title", description: "Existing human text")
        uploader = create(:confirmed_user, name: "Up Loader")
        ingest = Ingest.create!(kind: "division-summary", user: uploader, status: "done")
        AiDivisionSummary.create!(division: division, model: "local.Example", title: "Drafted title",
                                  description: "Drafted text", ingest: ingest)
      end

      it "shows the current summary and the AI drafts to pick from, to an admin who is also staff" do
        sign_in create(:confirmed_user, admin: true, staff: true)
        get edit_division_path_simple(division)

        expect(response.body).to include("Existing human title", "Use this draft", "Drafted title",
                                         "local.Example (uploaded by Up Loader)")
      end

      # DivisionPolicy only lets staff edit divisions, whatever else a user is.
      it "is not open to an admin who is not staff" do
        sign_in create(:confirmed_user, admin: true)
        expect { get edit_division_path_simple(division) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    it "lists Divisions, Policies, Members and Uploaded ingests together, after the divider" do
      get admin_division_path(division)
      items = response.parsed_body.css("nav.navigation a:not(.navigation__site-name), nav.navigation hr")
      names = items.map { |node| node.name == "hr" ? "---" : node.text.strip }
      expect(names).to eq(["Back to app", "Users", "Watches", "---", "Divisions", "Policies", "Members", "Uploaded ingests"])
    end

    it "says which site this is, in the menu and the browser tab" do
      get admin_division_path(division)
      expect(response.parsed_body.at_css("nav.navigation .navigation__site-name").text).to include("They Vote For You")
      expect(response.parsed_body.at_css("title").text).to include("They Vote For You admin")
    end

    it "separates the parliamentary data from the site's own records in the navigation" do
      get admin_division_path(division)
      expect(response.body).to include("navigation__divider")
    end

    it "updates a division" do
      patch admin_division_path(division), params: { division: { name: "Bills - Renamed" } }
      expect(division.reload.name).to eq("Bills - Renamed")
    end

    it "has no way to create a division, as they only come from the data import" do
      get admin_divisions_path
      expect(response.body).not_to include("New division")
      expect(self).not_to respond_to(:new_admin_division_path)
    end

    it "deletes a division" do
      division
      expect { delete admin_division_path(division) }.to change(Division, :count).by(-1)
    end
  end
end

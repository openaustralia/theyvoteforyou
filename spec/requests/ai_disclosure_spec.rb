# frozen_string_literal: true

require "spec_helper"

# Issue #1854: disclosing AI use in division summaries, behind the :ai_disclosure flag
describe "AI disclosure", type: :request do
  include Warden::Test::Helpers

  let(:division) { create(:division, house: "representatives", date: Date.new(2014, 1, 1), number: 1) }
  let(:division_path) { "/divisions/representatives/2014-01-01/1" }
  let(:staff_user) { create(:confirmed_user, staff: true) }
  let(:model_name) { "Claude Sonnet 5.5" }
  let(:flag_on) { false }

  before do
    Flipper.enable(:ai_disclosure) if flag_on
    # The division page only renders for divisions with their cached info and whips
    create(:division_info, division: division)
    create(:whip, division: division)
  end

  after do
    Flipper.disable(:ai_disclosure)
    Warden.test_reset!
  end

  shared_context "when signed in as staff" do
    before { login_as staff_user }
  end

  describe "GET edit form" do
    include_context "when signed in as staff"

    before do
      create(:wiki_motion, ai_assisted: true, ai_model: model_name)
      get "#{division_path}/edit"
    end

    context "with the flag off" do
      it { expect(response.body).not_to include("Drafted with AI assistance") }
    end

    context "with the flag on" do
      let(:flag_on) { true }

      it { expect(response.body).to include("Drafted with AI assistance") }
      it("offers earlier models to autocomplete") { expect(response.body).to include(model_name) }
    end
  end

  describe "POST update" do
    include_context "when signed in as staff"

    let(:params) { { newtitle: "A title", newdescription: "A summary" }.merge(ai_params) }
    let(:ai_params) { { ai_assisted: "1", ai_model: model_name } }
    let(:saved_summary) { division.reload.wiki_motion }

    before { post division_path, params: params }

    context "with the flag off" do
      it("ignores the AI fields") { expect(saved_summary.ai_assisted).to be_nil }
    end

    context "with the flag on" do
      let(:flag_on) { true }

      context "when AI assisted with a model" do
        it { expect(saved_summary.ai_assisted).to be true }
        it { expect(saved_summary.ai_model).to eq model_name }
      end

      context "when the box is unticked" do
        let(:ai_params) { { ai_assisted: "0" } }

        it { expect(saved_summary.ai_assisted).to be false }
      end

      context "when AI assisted but the model is missing" do
        let(:ai_params) { { ai_assisted: "1", ai_model: "" } }

        it { expect(response).to have_http_status(:unprocessable_content) }
        it("explains what's missing") { expect(response.body).to include("Enter the model you used") }
        it("keeps what the editor typed") { expect(response.body).to include("A summary") }
        it("saves nothing") { expect(division.reload.wiki_motion).to be_nil }
      end
    end
  end

  describe "GET division page" do
    before do
      create(:wiki_motion, division: division, ai_assisted: ai_assisted, ai_model: ai_assisted ? model_name : nil)
      get division_path
    end

    context "with the flag off and an AI assisted summary" do
      let(:ai_assisted) { true }

      it { expect(response.body).not_to include("drafted with AI assistance") }
    end

    context "with the flag on" do
      let(:flag_on) { true }

      context "when the summary used AI" do
        let(:ai_assisted) { true }

        it { expect(response.body).to include("drafted with AI assistance (model: #{model_name})") }
      end

      context "when the summary didn't use AI" do
        let(:ai_assisted) { false }

        it { expect(response.body).not_to include("drafted with AI assistance") }
      end

      context "when AI use is unknown" do
        let(:ai_assisted) { nil }

        it { expect(response.body).not_to include("drafted with AI assistance") }
      end
    end
  end

  describe "GET /help/ai" do
    before { get "/help/ai" }

    context "with the flag off" do
      it { expect(response).to have_http_status(:not_found) }
    end

    context "with the flag on" do
      let(:flag_on) { true }

      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe "GET /api/v1/divisions" do
    subject(:ids) { response.parsed_body.pluck("id") }

    let(:api_key) { create(:confirmed_user).api_key }
    let(:filter) { {} }
    let!(:unedited) { create(:division, house: "senate", date: Date.new(2014, 1, 1), number: 2) }
    let!(:with_ai) { create(:division, house: "senate", date: Date.new(2014, 1, 1), number: 3) }
    let!(:without_ai) { create(:division, house: "senate", date: Date.new(2014, 1, 1), number: 4) }
    let!(:unknown) { create(:division, house: "senate", date: Date.new(2014, 1, 1), number: 5) }

    before do
      create(:wiki_motion, division: with_ai, ai_assisted: true, ai_model: model_name)
      create(:wiki_motion, division: without_ai, ai_assisted: false)
      create(:wiki_motion, division: unknown)
      get "/api/v1/divisions.json", params: { key: api_key, house: "senate" }.merge(filter)
    end

    context "without a filter" do
      let(:entry) { response.parsed_body.find { |d| d["id"] == with_ai.id } }

      it { expect(entry).to include("ai_assisted" => true) }
      it { expect(entry).to include("ai_model" => model_name) }
    end

    context "with ai_assisted=true" do
      let(:filter) { { ai_assisted: "true" } }

      it { is_expected.to eq [with_ai.id] }
    end

    context "with ai_assisted=false" do
      let(:filter) { { ai_assisted: "false" } }

      it { is_expected.to eq [without_ai.id] }
    end

    context "with ai_assisted=null" do
      let(:filter) { { ai_assisted: "null" } }

      it("includes divisions with no summary") { is_expected.to contain_exactly(unedited.id, unknown.id) }
    end

    context "when a later summary replaces an AI assisted one" do
      let(:filter) { { ai_assisted: "true" } }
      let(:later_summary) { create(:wiki_motion, division: with_ai, ai_assisted: false, created_at: Time.zone.local(2015, 1, 1)) }

      it("filters on the latest summary only") do
        later_summary
        get "/api/v1/divisions.json", params: { key: api_key, house: "senate" }.merge(filter)
        expect(response.parsed_body.pluck("id")).to be_empty
      end
    end
  end
end

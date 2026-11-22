# frozen_string_literal: true

require "spec_helper"
# Compare results of rendering pages via rails and via the old php app

describe HelpController, type: :request do
  include HTMLCompareHelper

  include_context "with fixtures"

  it "#research" do
    compare_static("/help/research")
  end

  it "#data says what is recorded about API calls" do
    get "/help/data"
    expect(Capybara.string(response.body)).to have_css("h2#logging", text: "What we record when you use the API")
  end
end

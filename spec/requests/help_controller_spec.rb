# frozen_string_literal: true

require "spec_helper"
# Compare results of rendering pages via rails and via the old php app

describe HelpController, type: :request do
  include HTMLCompareHelper
  include_context "with fixtures"

  it "#research" do
    compare_static("/help/research")
  end
end

# frozen_string_literal: true

require "spec_helper"

describe UsersHelper, type: :helper do
  describe "#name_with_badge" do
    it "shows the user is unknown instead of raising when there's no user" do
      expect(helper.name_with_badge(nil)).to eq "Unknown user"
    end
  end
end

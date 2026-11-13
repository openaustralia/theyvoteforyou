# frozen_string_literal: true

require "spec_helper"

describe "Editing a division", type: :feature do
  let(:division) { create(:division, house: "senate") }
  let(:staff_user) { create(:confirmed_user, staff: true) }

  before do
    login_as staff_user
  end

  it "shows a markdown preview of the summary", :js do
    visit "/divisions/#{division.house}/#{division.date}/#{division.number}/edit"
    fill_in "newdescription", with: "A **bold** summary"
    click_on "Preview"
    expect(page).to have_css("#preview strong", text: "bold")
  end
end

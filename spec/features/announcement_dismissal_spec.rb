# frozen_string_literal: true

require "spec_helper"

# The bar's close button and cookie are an inline script, so these run in a real browser
describe "Dismissing the announcement bar", :js, type: :feature do
  let!(:announcement) { create(:announcement, body: "Browser check notice") }

  it "shows the bar with a close button" do
    visit about_path
    expect(page).to have_css(".site-announcement", text: "Browser check notice")
    # Capybara only finds visible elements, so this also shows the script revealed the button
    expect(page).to have_css(".site-announcement-close")
  end

  it "hides the bar when it is dismissed, and keeps it hidden on other pages" do
    visit about_path
    find(".site-announcement-close").click
    expect(page).to have_no_css(".site-announcement")

    visit policies_path
    expect(page).to have_css("nav.site-header")
    expect(page).to have_no_css(".site-announcement")
  end

  it "remembers the dismissal for 24 hours" do
    visit about_path
    find(".site-announcement-close").click
    expect(page).to have_no_css(".site-announcement")

    cookie = page.driver.browser.manage.cookie_named("tvfy_announcement")
    expect(cookie[:value]).to eq announcement.dismissal_key
    seconds_left = cookie[:expires].to_i - Time.now.to_i
    expect(seconds_left).to be_within(5.minutes.to_i).of(24.hours.to_i)
  end

  it "shows the bar again when the announcement is edited" do
    visit about_path
    find(".site-announcement-close").click
    expect(page).to have_no_css(".site-announcement")

    announcement.update!(body: "Browser check notice, reworded")
    visit about_path
    expect(page).to have_css(".site-announcement", text: "reworded")
  end

  it "shows a different announcement that was published after the dismissal" do
    visit about_path
    find(".site-announcement-close").click
    expect(page).to have_no_css(".site-announcement")

    create(:announcement, body: "A newer notice")
    visit about_path
    expect(page).to have_css(".site-announcement", text: "A newer notice")
  end

  it "moves keyboard focus to the site name when dismissed from the keyboard" do
    visit about_path
    find(".site-announcement-close").send_keys(:enter)
    expect(page).to have_no_css(".site-announcement")
    expect(page.evaluate_script("document.activeElement.className")).to include("navbar-brand")
  end
end

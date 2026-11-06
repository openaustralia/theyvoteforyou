# frozen_string_literal: true

require "spec_helper"

# The theme is applied by JavaScript and CSS media queries, so these run in a real browser
describe "Choosing a light or dark theme", :js, type: :feature do
  let(:light_background) { "rgb(255, 255, 255)" }
  let(:dark_background) { "rgb(22, 25, 30)" }

  before do
    # Wide enough that the header menu isn't collapsed behind the toggle button
    page.driver.browser.manage.window.resize_to(1280, 800)
    # Headless Chrome otherwise follows the host machine's own setting, which differs between developers and CI
    emulate_system_theme("light")
  end

  # The browser is reused between examples, so don't let an emulated system setting or a saved choice carry over.
  # An empty value turns the emulation off.
  after do
    emulate_system_theme("")
    page.execute_script("localStorage.clear()")
  end

  def body_background
    page.evaluate_script("getComputedStyle(document.body).backgroundColor")
  end

  def data_theme
    page.evaluate_script("document.documentElement.getAttribute('data-theme')")
  end

  def choose_theme(label)
    find_by_id("theme-nav-toggle").click
    within(".theme-nav .dropdown-menu") { click_link label }
  end

  def emulate_system_theme(scheme)
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [{ name: "prefers-color-scheme", value: scheme }])
  end

  it "follows the system setting until a theme is chosen" do
    visit about_path
    expect(page).to have_css(".theme-nav [data-theme-choice='system'][aria-checked='true']", visible: :all)
    expect(data_theme).to be_nil
    expect(body_background).to eq light_background

    emulate_system_theme("dark")
    expect(body_background).to eq dark_background
  end

  it "switches to the dark theme and remembers it on other pages" do
    visit about_path
    choose_theme "Dark"
    expect(data_theme).to eq "dark"
    expect(body_background).to eq dark_background

    visit policies_path
    expect(page).to have_css("nav.site-header")
    expect(data_theme).to eq "dark"
    expect(page).to have_css(".theme-nav [data-theme-choice='dark'][aria-checked='true']", visible: :all)
  end

  it "draws keyboard focus outlines in a light colour on the dark theme" do
    visit about_path
    choose_theme "Dark"
    page.execute_script("document.querySelector('.navbar-brand').focus()")
    expect(page.evaluate_script("getComputedStyle(document.activeElement).outlineColor")).to eq "rgb(232, 234, 238)"
  end

  it "keeps danger alert text light on hover in the dark theme" do
    visit about_path
    choose_theme "Dark"
    # No page shows a danger alert without setting up data for it, and only the stylesheet is under test here
    page.execute_script(<<~JS)
      var alert = document.createElement("div");
      alert.className = "alert alert-danger";
      alert.id = "test-alert";
      alert.textContent = "Test alert";
      document.querySelector(".main-content").prepend(alert);
    JS
    find_by_id("test-alert").hover
    expect(page.evaluate_script("getComputedStyle(document.getElementById('test-alert')).color")).to eq "rgb(240, 169, 167)"
  end

  it "keeps the light theme when the system is dark, if light was chosen" do
    visit about_path
    emulate_system_theme("dark")
    choose_theme "Light"
    expect(body_background).to eq light_background
  end

  it "goes back to following the system when System is chosen" do
    visit about_path
    choose_theme "Dark"
    choose_theme "System"
    expect(data_theme).to be_nil
    expect(page.evaluate_script("localStorage.getItem('tvfy-theme')")).to be_nil
    expect(body_background).to eq light_background
  end
end

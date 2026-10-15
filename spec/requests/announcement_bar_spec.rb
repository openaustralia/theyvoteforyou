# frozen_string_literal: true

require "spec_helper"

describe "Announcement bar", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:dismissal_key_pattern) { /data-dismissal-key=["']([^"']+)["']/ }

  it "shows the current announcement to a logged-out visitor" do
    create(:announcement, body: "We are updating the voting data tonight.")
    get about_path
    expect(response.body).to include("We are updating the voting data tonight.")
  end

  it "shows nothing when no announcement is live" do
    create(:announcement, published: false)
    get about_path
    expect(response.body).not_to include("site-announcement")
  end

  it "shows only the newest live announcement" do
    create(:announcement, body: "An older notice", created_at: 2.days.ago)
    create(:announcement, body: "The newer notice", created_at: 1.day.ago)
    get about_path
    expect(response.body).to include("The newer notice")
    expect(response.body).not_to include("An older notice")
  end

  it "keeps links and removes scripts from the body" do
    create(:announcement, body: %(See <a href="https://example.org/news">the news</a>.<script>alert(1)</script>))
    get about_path
    expect(response.body).to include(%(<a href="https://example.org/news">the news</a>))
    expect(response.body).not_to include("<script>alert(1)</script>")
  end

  it "removes images and headings, which do not belong in a one-line bar" do
    create(:announcement, body: %(<h1>Big</h1><img src="https://example.org/pixel.png">Notice text))
    get about_path
    expect(response.body).to include("Notice text")
    expect(response.body).not_to include("example.org/pixel.png")
    expect(response.body).not_to include("<h1>Big</h1>")
  end

  it "does not show an announcement that has ended or not started" do
    create(:announcement, body: "Ended notice", ends_at: 1.hour.ago)
    create(:announcement, body: "Future notice", starts_at: 1.hour.from_now)
    get about_path
    expect(response.body).not_to include("Ended notice")
    expect(response.body).not_to include("Future notice")
  end

  it "still renders the page when the announcement cannot be loaded" do
    allow(Announcement).to receive(:current).and_raise(ActiveRecord::ConnectionNotEstablished)
    get about_path
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("site-announcement")
  end

  describe "dismissing" do
    it "gives the bar a key and a close button that scripts reveal" do
      announcement = create(:announcement)
      get about_path
      expect(response.body[dismissal_key_pattern, 1]).to eq announcement.dismissal_key
      expect(response.body).to include("site-announcement-close")
    end

    it "gives the bar a new key after the announcement is edited" do
      announcement = create(:announcement)
      get about_path
      original = response.body[dismissal_key_pattern, 1]
      travel 1.minute
      announcement.update!(body: "Edited")
      get about_path
      expect(response.body[dismissal_key_pattern, 1]).not_to eq original
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

describe Person do
  describe "portrait urls" do
    let(:person) { build_stubbed(:person, large_image_url: "https://www.openaustralia.org.au/images/mpsL/10001.jpg") }

    it "serves the portrait from this site rather than the source" do
      expect(person.large_image_url).to eq "/system/portraits/large/#{person.id}.jpg"
    end

    it "still knows where the portrait came from" do
      expect(person.large_image_source_url).to eq "https://www.openaustralia.org.au/images/mpsL/10001.jpg"
    end

    it "has no portrait url without a source" do
      expect(person.small_image_url).to be_nil
      expect(person.small_image_source_url).to be_nil
      expect(person).not_to be_show_small_image
    end
  end
end

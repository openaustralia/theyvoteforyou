# frozen_string_literal: true

require "spec_helper"

describe DataLoader::People do
  describe ".load_missing_images!" do
    let(:person) { create(:person, small_image_url: nil, large_image_url: nil, extra_large_image_url: nil) }
    let(:root) { Rails.root.join("tmp/test_portraits") }

    before do
      stub_const("PortraitMirror::ROOT", root)
      stub_request(:get, "https://www.openaustralia.org.au/images/mps/#{person.id}.jpg").to_return(status: 404)
      stub_request(:get, "https://www.openaustralia.org.au/images/mpsL/#{person.id}.jpg")
        .to_return(status: 200, body: "large jpeg", headers: { "Content-Type" => "image/jpeg" })
      stub_request(:get, "https://www.openaustralia.org.au/images/mpsXL/#{person.id}.jpg").to_return(status: 404)
    end

    after { FileUtils.rm_rf(root) }

    it "records the source url for each portrait size that exists" do
      described_class.load_missing_images!
      person.reload
      expect(person.small_image_source_url).to be_nil
      expect(person.large_image_source_url).to eq "https://www.openaustralia.org.au/images/mpsL/#{person.id}.jpg"
      expect(person.extra_large_image_source_url).to be_nil
    end

    it "mirrors a newly found portrait straight away" do
      described_class.load_missing_images!
      expect(File.binread(root.join("large/#{person.id}.jpg"))).to eq "large jpeg"
    end
  end
end

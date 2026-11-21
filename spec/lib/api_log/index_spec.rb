# frozen_string_literal: true

require "spec_helper"

# Creating and counting need Elasticsearch, which CI doesn't have, so only the names are checked here
describe ApiLog::Index do
  it "files each call under the month it was made, in UTC" do
    expect(described_class.monthly_name(Time.new(2014, 4, 1, 9, 0, 0, "+10:00"))).to eq "tvfy_api_test_2014.03"
  end

  it "names a yearly index so the same pattern matches it and the monthly ones" do
    expect(described_class.yearly_name(2014)).to eq "tvfy_api_test_2014"
  end
end

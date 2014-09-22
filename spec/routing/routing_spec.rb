require 'spec_helper'

describe "path helpers", type: :helper do
  it ".member_path" do
    member = mock_model(Member, url_name: "Foo_Bar", url_electorate: "Twist",
      australian_house: "representatives")
    expect(helper.member_path(member)).
      to eq "/members/representatives/twist/foo_bar"
  end
end

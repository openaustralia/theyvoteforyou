require 'spec_helper'

describe "path helpers", type: :helper do
  it do
    member = mock_model(Member, url_name: "Foo_Bar", url_electorate: "Twist",
      australian_house: "representatives")
    expect(helper.member_path2(member)).
      to eq "/members/representatives/twist/foo_bar"
  end
end

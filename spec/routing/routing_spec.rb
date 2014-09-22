require 'spec_helper'

describe "path helpers", type: :helper do
  let(:member) { mock_model(Member, url_name: "Foo_Bar", url_electorate: "Twist",
    australian_house: "representatives") }

  it ".member_path" do
    expect(helper.member_path(member)).
      to eq "/members/representatives/twist/foo_bar"
  end

  it ".member_policy_path" do
    policy = mock_model(Policy, id: 123)
    expect(helper.member_policy_path(member, policy)).
      to eq "/members/representatives/twist/foo_bar/policies/123"
  end
end

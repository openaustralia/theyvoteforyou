require 'spec_helper'

describe "path helpers", type: :helper do
  let(:member) { mock_model(Member, url_name: "Foo_Bar", url_electorate: "Twist",
    australian_house: "representatives") }
  let(:policy) { mock_model(Policy, id: 123) }

  it ".member_path" do
    expect(helper.member_path(member)).
      to eq "/members/representatives/twist/foo_bar"
  end

  it ".member_policy_path" do
    expect(helper.member_policy_path(member, policy)).
      to eq "/members/representatives/twist/foo_bar/policies/123"
  end

  it ".full_member_policy_path" do
    expect(helper.full_member_policy_path(member, policy)).
      to eq "/members/representatives/twist/foo_bar/policies/123/full"
  end

  it ".member_divisions_path" do
    expect(helper.member_divisions_path(member)).
      to eq "/members/representatives/twist/foo_bar/divisions"
  end

  it ".friends_member_path" do
    expect(helper.friends_member_path(member)).
      to eq "/members/representatives/twist/foo_bar/friends"
  end
end

# frozen_string_literal: true

require "spec_helper"

describe "path helpers", type: :helper do
  let(:member) do
    stub_model(Member, url_name: "Foo_Bar", url_electorate: "Twist",
                       house: "representatives")
  end
  let(:policy) { mock_model(Policy, id: 123) }
  let(:division) { stub_model(Division, house: "representatives", date: Date.new(2001, 1, 1), number: 3) }
  let(:party) { instance_double("party", url_name: "foo_bar") }

  it ".member_path_simple" do
    expect(helper.member_path_simple(member))
      .to eq "/people/representatives/twist/foo_bar"
  end

  it ".member_policy_path_simple" do
    expect(helper.member_policy_path_simple(member, policy))
      .to eq "/people/representatives/twist/foo_bar/policies/123"
  end

  it ".member_divisions_path_simple" do
    expect(helper.member_divisions_path_simple(member))
      .to eq "/people/representatives/twist/foo_bar/divisions"
  end

  it ".friends_member_path_simple" do
    expect(helper.friends_member_path_simple(member))
      .to eq "/people/representatives/twist/foo_bar/friends"
  end

  it ".division_path_simple" do
    expect(helper.division_path_simple(division))
      .to eq "/divisions/representatives/2001-01-01/3"
  end

  it ".edit_division_path_simple" do
    expect(helper.edit_division_path_simple(division))
      .to eq "/divisions/representatives/2001-01-01/3/edit"
  end

  it ".history_division_path_simple" do
    expect(helper.history_division_path_simple(division))
      .to eq "/divisions/representatives/2001-01-01/3/history"
  end
end

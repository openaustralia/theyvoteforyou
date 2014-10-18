require 'spec_helper'

describe "path helpers", type: :helper do
  let(:member) { mock_model(Member, url_name: "Foo_Bar", url_electorate: "Twist",
    house: "representatives") }
  let(:policy) { mock_model(Policy, id: 123) }
  let(:division) { mock_model(Division, house: "representatives", date: Date.new(2001,1,1), number: 3) }
  let(:party) { double("party", url_name: "foo_bar") }

  it ".member_path" do
    expect(helper.member_path(member)).
      to eq "/people/representatives/twist/foo_bar"
  end

  it ".member_policy_path" do
    expect(helper.member_policy_path(member, policy)).
      to eq "/people/representatives/twist/foo_bar/policies/123"
  end

  it ".member_divisions_path" do
    expect(helper.member_divisions_path(member)).
      to eq "/people/representatives/twist/foo_bar/divisions"
  end

  it ".friends_member_path" do
    expect(helper.friends_member_path(member)).
      to eq "/people/representatives/twist/foo_bar/friends"
  end

  it ".division_path" do
    expect(helper.division_path(division)).
      to eq "/divisions/representatives/2001-01-01/3"
  end

  it ".edit_division_path" do
    expect(helper.edit_division_path(division)).
      to eq "/divisions/representatives/2001-01-01/3/edit"
  end

  it ".electorate_path" do
    expect(helper.electorate_path(member)).
      to eq "/people/representatives/twist"
  end

  it ".member_division_path" do
    expect(helper.member_division_path(member, division)).
      to eq "/people/representatives/twist/foo_bar/divisions/2001-01-01/3"
  end

  it ".history_division_path" do
    expect(helper.history_division_path(division)).
      to eq "/divisions/representatives/2001-01-01/3/history"
  end

  it ".party_divisions_path" do
    expect(helper.party_divisions_path(party)).
      to eq "/parties/foo_bar/divisions"
  end
end

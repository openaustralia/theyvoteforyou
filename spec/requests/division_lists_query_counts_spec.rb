# frozen_string_literal: true

require "spec_helper"

# A page that lists divisions must not run more queries as the list gets longer. The divisions/_division partial used
# to look up the member's vote, and everything hanging off it, once for every division it showed.
describe "Query counts for lists of divisions", type: :request do
  def count_queries(&)
    count = 0
    counter = lambda do |_name, _start, _finish, _id, payload|
      next if payload[:cached] || payload[:name] == "SCHEMA" || payload[:sql].match?(/\A\s*(BEGIN|COMMIT|SAVEPOINT|RELEASE)/i)

      count += 1
    end
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &)
    count
  end

  # A division in 2014 where the member voted against their party's whip, so it shows up in every list under test.
  # When another member is given, they cast other_vote.
  def add_division(member, index, other: nil, other_vote: "aye")
    division = create(:division, date: Date.new(2014, 1, 1) + index, number: index + 1, name: "Division #{index}")
    create(:division_info, division: division, rebellions: 1)
    create(:whip, division: division, party: member.party, whip_guess: "aye")
    create(:vote, member: member, division: division, vote: "no")
    return unless other

    create(:whip, division: division, party: other.party, whip_guess: "aye")
    create(:vote, member: other, division: division, vote: other_vote)
  end

  # The number of queries the page runs once it has this many divisions
  def queries_with(division_count, member, path, other: nil, other_vote: "aye")
    (member.votes.count...division_count).each { |index| add_division(member, index, other: other, other_vote: other_vote) }
    get path
    expect(response).to have_http_status(:ok)
    count_queries { get path }
  end

  # The lists are compared at 4 and 12 divisions, not 3 and 12. A member's page also lists their 3 most recent
  # divisions, and with 3 or fewer the two lists ask for the same votes, so Rails' query cache answers the second.
  let(:member) { create(:member) }

  it "runs the same queries for a member's votes with 12 divisions as with 4" do
    path = member_divisions_path(member.url_params.merge(date: "2014"))

    few = queries_with(4, member, path)
    many = queries_with(12, member, path)

    expect(many).to eq(few), "expected 12 divisions to run #{few} queries, as 4 do, but it ran #{many}"
  end

  it "runs the same queries for a member's page with 12 rebellious divisions as with 4" do
    create(:member_info, member: member)
    path = member_path(member.url_params)

    few = queries_with(4, member, path)
    many = queries_with(12, member, path)

    expect(many).to eq(few), "expected 12 divisions to run #{few} queries, as 4 do, but it ran #{many}"
  end

  # The compare page lists the divisions of whichever kind is fewer: when they voted differently less often than
  # the same, it lists the different ones, and otherwise the same ones.
  describe "comparing two people" do
    let(:other) { create(:member, first_name: "Other", last_name: "Person", constituency: "Elsewhere", party: "Labor") }
    let(:path) do
      compare_member_path(
        member.url_params.merge(house2: other.house, mpc2: other.url_electorate.downcase, mpn2: other.url_name.downcase)
      )
    end

    it "runs the same queries for 12 divisions as for 4 when it lists the ones they voted differently in" do
      create(:people_distance, person1: member.person, person2: other.person, nvotesdiffer: 1, nvotessame: 5)

      few = queries_with(4, member, path, other: other, other_vote: "aye")
      many = queries_with(12, member, path, other: other, other_vote: "aye")

      expect(many).to eq(few), "expected 12 divisions to run #{few} queries, as 4 do, but it ran #{many}"
    end

    it "runs the same queries for 12 divisions as for 4 when it lists the ones they voted the same in" do
      create(:people_distance, person1: member.person, person2: other.person, nvotesdiffer: 5, nvotessame: 1)

      few = queries_with(4, member, path, other: other, other_vote: "no")
      many = queries_with(12, member, path, other: other, other_vote: "no")

      expect(many).to eq(few), "expected 12 divisions to run #{few} queries, as 4 do, but it ran #{many}"
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

# The divisions/_division partial used to look up the member's vote, and everything hanging off it, once for every
# division it showed. These specs check that a page listing divisions runs the same queries however long the list is,
# and that the lists still say what each member did.
describe "Lists of divisions", type: :request do
  def count_queries(&)
    count = 0
    counter = lambda do |_name, _start, _finish, _id, payload|
      next if payload[:cached] || payload[:name] == "SCHEMA" || payload[:sql].match?(/\A\s*(BEGIN|COMMIT|SAVEPOINT|RELEASE)/i)

      count += 1
    end
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &)
    count
  end

  # A division in 2014 with a whip of "aye" for the party of each member who voted in it. Anyone left out of votes
  # was absent.
  def add_division(index)
    division = create(:division, date: Date.new(2014, 1, 1) + index, number: index + 1, name: "Division #{index}")
    create(:division_info, division: division, rebellions: 1)
    votes.keys.map(&:party).uniq.each { |party| create(:whip, division: division, party: party, whip_guess: "aye") }
    votes.each { |voter, vote| create(:vote, member: voter, division: division, vote: vote) }
  end

  # The number of queries the page runs once it lists this many divisions
  def queries_with(division_count)
    (member.votes.count...division_count).each { |index| add_division(index) }
    get path
    count_queries { get path }
  end

  let(:member) { create(:member) }
  let(:votes) { { member => "no" } }

  # The member page also lists the 3 most recent divisions. With 3 or fewer, both lists ask for the same votes and
  # Rails' query cache answers the second, so the lists are compared at 4 and 12 divisions, not 3 and 12.
  shared_examples "a list whose queries do not grow" do
    it "runs the same queries for 12 as for 4" do
      few = queries_with(4)
      many = queries_with(12)

      expect(response).to have_http_status(:ok)
      expect(many).to eq(few), "expected 12 divisions to run #{few} queries, as 4 do, but it ran #{many}"
    end
  end

  describe "GET /people/:house/:mpc/:mpn/divisions" do
    let(:path) { member_divisions_path(member.url_params.merge(date: "2014")) }

    it_behaves_like "a list whose queries do not grow"

    context "when the member voted against their party" do
      before { add_division(0) }

      it "says they rebelled" do
        get path

        expect(response.body).to include("voted No, rebelling against the Australian Greens")
      end
    end

    context "when the member voted with their party" do
      let(:votes) { { member => "aye" } }

      before { add_division(0) }

      it "says how they voted" do
        get path

        expect(response.body).to include("voted Yes")
      end
    end

    context "when the member did not vote" do
      let(:votes) { {} }

      before { add_division(0) }

      it "says they were absent" do
        get path

        expect(response.body).to include("was absent")
      end
    end

    # Whip#free_vote? is a fixed list of known free votes, by house, date and party
    context "when it was one of the free votes" do
      let(:member) { create(:member, party: "Liberal Party") }
      let(:path) { member_divisions_path(member.url_params.merge(date: "2006")) }

      before do
        division = create(:division, date: Date.new(2006, 2, 16), number: 1)
        create(:division_info, division: division)
        create(:whip, division: division, party: "Liberal Party", whip_guess: "aye")
        create(:vote, member: member, division: division, vote: "aye")
      end

      it "says so" do
        get path

        expect(response.body).to include("voted Yes in this free vote")
      end
    end
  end

  describe "GET /people/:house/:mpc/:mpn" do
    let(:path) { member_path(member.url_params) }

    before { create(:member_info, member: member) }

    it_behaves_like "a list whose queries do not grow"
  end

  describe "GET /people/:house/:mpc/:mpn/compare/..." do
    let(:other) { create(:member, first_name: "Other", last_name: "Person", constituency: "Elsewhere", party: "Labor") }
    let(:path) do
      compare_member_path(
        member.url_params.merge(house2: other.house, mpc2: other.url_electorate.downcase, mpn2: other.url_name.downcase)
      )
    end

    # The page lists whichever kind of division is fewer
    context "when they voted differently less often" do
      let(:votes) { { member => "no", other => "aye" } }

      before { create(:people_distance, person1: member.person, person2: other.person, nvotesdiffer: 1, nvotessame: 5) }

      it_behaves_like "a list whose queries do not grow"

      it "says how each of them voted" do
        add_division(0)
        get path

        expect(response.body).to include("voted No, rebelling against the Australian Greens").and include("voted Yes")
      end
    end

    context "when they voted the same less often" do
      let(:votes) { { member => "no", other => "no" } }

      before { create(:people_distance, person1: member.person, person2: other.person, nvotesdiffer: 5, nvotessame: 1) }

      it_behaves_like "a list whose queries do not grow"
    end

    # Some divisions have a person's vote on the member record from before they changed party
    context "when a vote is on the person's earlier member record" do
      let(:earlier) do
        create(:member, person: member.person, party: "Liberal Party", entered_house: "2001-01-01", left_house: "2004-12-31")
      end
      let(:votes) { { earlier => "no", other => "aye" } }

      before { create(:people_distance, person1: member.person, person2: other.person, nvotesdiffer: 1, nvotessame: 5) }

      it "lists the vote under that record" do
        add_division(0)
        get path

        expect(response.body).to include("voted No, rebelling against the Liberal Party")
      end
    end
  end
end

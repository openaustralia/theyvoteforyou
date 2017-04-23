require 'spec_helper'
# Compare results of rendering pages via rails and via the old php app

describe HomeController, type: :request do
  include HTMLCompareHelper

  # TODO: Do we really need this test?
  #       The homepage was written from scratch
  #       at the end of the rails upgrade and doesn't include complex
  #       behaviour that could easily regress.
  it "#index" do
    clear_db_of_fixture_data
    create_members
    compare_static("/")
  end

  # TODO: Do we really need this test?
  #       The only dynamic content on this page is the paragraph with
  #       summary data. We could extract that to a helper and write specific
  #       tests to guard from regression.
  describe "#faq" do
    before do
      clear_db_of_fixture_data
      create_members
      create_divisions
      create_votes
      create_users
      create_policies
      create_wiki_motions
    end

    it { compare_static("/faq.php") }
  end

  describe "#search" do
    # TODO: Do we really need this test?
    #       The redirect is already covered in spec/routing/redirects_spec.rb:246
    #       Aside from that, this is a static page with no complex logic to regress.
    it {compare_static("/search.php")}

    describe "postcode lookups" do
      before do
        clear_db_of_fixture_data
        create_people
        create_members
        create_offices
        create_member_infos
        create_member_distances

        create_policies
        create_policy_person_distances

        create_divisions
        create_votes
        create_whips
        create_wiki_motions
      end

      around do |spec|
        VCR.use_cassette('openaustralia_postcode_api') do
          spec.run
        end
      end

      # TODO: These tests cover too much behaviour and should be more focused:
      #       They're currently testing:
      #         * the php redirects
      #         * the postcode lookup controller behaviour
      #         * that each page rendered matches the static regression fixture copy
      #       Some of this is covered in other tests and we should write isolated tests
      #       for the rest, and an integration test if it's needed.
      context "when one MP is covered by the postcode" do
        it "goes direct to MP page" do
          compare_static("/search.php?query=2088&button=Search")
        end
      end

      context "when two electorates cover this postcode" do
        it "presents options to the searcher" do
          compare_static("/search.php?query=2042&button=Search")
        end
      end

      context "when the postcode is not a real postcode" do
        it { compare_static("/search.php?query=0000&button=Search") }
      end
    end
  end
end

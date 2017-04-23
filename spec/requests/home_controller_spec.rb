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

      # Goes direct to MP page (only one MP covered by this postcode)
      it do
        compare_static("/search.php?query=2088&button=Search")
      end

      # Two electorates cover this postcode
      it do
        compare_static("/search.php?query=2042&button=Search")
      end

      # Bad postcode
      it do
        compare_static("/search.php?query=0000&button=Search")
      end
    end
  end
end

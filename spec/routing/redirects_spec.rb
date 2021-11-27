# frozen_string_literal: true

require "spec_helper"

describe "routing redirects", type: :request do
  fixtures :all

  # This is an old url still being used by openaustralia.org.au
  it "/mp.php?mpid=1&dmp=1 -> /mp.php?house=representatives&mpc=Warringah&mpn=Tony_Abbott&dmp=1" do
    get "/mp.php?mpid=1&dmp=1", params: {}
    expect(response).to redirect_to("/mp.php?dmp=1&house=representatives&mpc=Warringah&mpn=Tony_Abbott")
  end

  it "/mp.php?display=allvotes&dmp=1&house=senate&mpc=Tasmania&mpn=Eric_Abetz -> /mp.php?dmp=1&house=senate&mpc=Tasmania&mpn=Eric_Abetz" do
    get "/mp.php?display=allvotes&dmp=1&house=senate&mpc=Tasmania&mpn=Eric_Abetz", params: {}
    expect(response).to redirect_to("/mp.php?dmp=1&house=senate&mpc=Tasmania&mpn=Eric_Abetz")
  end

  it "/mp.php?display=allvotes&id=uk.org.publicwhip/member/1 -> /mp.php?display=allvotes&house=representatives&mpc=Warringah&mpn=Tony_Abbott" do
    get "/mp.php?display=allvotes&id=uk.org.publicwhip/member/1", params: {}
    expect(response).to redirect_to("/mp.php?display=allvotes&house=representatives&mpc=Warringah&mpn=Tony_Abbott")
  end

  it "/mp.php?display=summary&house=representatives&mpc=Warringah&mpn=Tony_Abbott -> /mp.php?house=representatives&mpc=Warringah&mpn=Tony_Abbott" do
    get "/mp.php?display=summary&house=representatives&mpc=Warringah&mpn=Tony_Abbott", params: {}
    expect(response).to redirect_to("/mp.php?house=representatives&mpc=Warringah&mpn=Tony_Abbott")
  end

  it do
    get "/mp.php?house=representatives&mpc=Warringah", params: {}
    expect(response).to redirect_to "/members/representatives/warringah"
  end

  it do
    get "/mp.php?display=alldreams&house=senate&mpc=Tasmania&mpn=Eric_Abetz", params: {}
    expect(response).to redirect_to "/mp.php?house=senate&mpc=Tasmania&mpn=Eric_Abetz"
  end

  it do
    get "/mp.php?house=senate&mpc=Senate&mpn=Judith_Adams", params: {}
    expect(response).to redirect_to "/mp.php?house=senate&mpc=WA&mpn=Judith_Adams"
  end

  it do
    get "/mp.php?house=representatives&mpn=Tony_Abbott", params: {}
    expect(response).to redirect_to "/mp.php?house=representatives&mpc=Warringah&mpn=Tony_Abbott"
  end

  it do
    get "/mp.php?mpn=Tony_Abbott", params: {}
    expect(response).to redirect_to "/mp.php?house=representatives&mpc=Warringah&mpn=Tony_Abbott"
  end

  it do
    get "/mp.php?house=representatives&mpc=Warringah&mpn=Tony_Abbott", params: {}
    expect(response).to redirect_to "/members/representatives/warringah/tony_abbott"
  end

  it do
    get "/mp.php?house=representatives&mpc=Warringah&mpn=Tony_Abbott?display=allvotes", params: {}
    expect(response).to redirect_to "/members/representatives/warringah/tony_abbott?display=allvotes"
  end

  it do
    get "/mp.php?house=representatives&mpc=Warringah&mpn=Tony_Abbott&dmp=1", params: {}
    expect(response).to redirect_to "/members/representatives/warringah/tony_abbott/policies/1"
  end

  it do
    get "/mp.php?house=representatives&mpc=Warringah&mpn=Tony_Abbott&display=motions&dmp=1", params: {}
    expect(response).to redirect_to "/members/representatives/warringah/tony_abbott/policies/1/full"
  end

  it do
    get "/mp.php?display=allfriends&house=senate&mpc=Tasmania&mpn=Eric_Abetz", params: {}
    expect(response).to redirect_to "/members/senate/tasmania/eric_abetz/friends"
  end

  it do
    get "/mp.php?display=everyvote&house=senate&mpc=Tasmania&mpn=Eric_Abetz", params: {}
    expect(response).to redirect_to "/members/senate/tasmania/eric_abetz/divisions"
  end

  it do
    get "/mp.php?mpn=Tony_Windsor&mpc=New%20England&house=representatives", params: {}
    expect(response).to redirect_to "/members/representatives/new_england/tony_windsor"
  end

  it do
    get "/members/representatives/lilley/wayne_swan/policies/3/full", params: {}
    expect(response).to redirect_to "/members/representatives/lilley/wayne_swan/policies/3"
  end

  it do
    get "/members", params: {}
    expect(response).to redirect_to "/people"
  end

  it do
    get "/members/representatives", params: {}
    expect(response).to redirect_to "/people/representatives"
  end

  it do
    get "/members?sort=attendance", params: {}
    expect(response).to redirect_to "/people?sort=attendance"
  end

  it do
    get "/members/representatives?sort=attendance", params: {}
    expect(response).to redirect_to "/people/representatives?sort=attendance"
  end

  it do
    get "/members/representatives/melbourne", params: {}
    expect(response).to redirect_to "/people/representatives/melbourne"
  end

  it do
    get "/members/representatives/warringah/tony_abbott", params: {}
    expect(response).to redirect_to "/people/representatives/warringah/tony_abbott"
  end

  it do
    get "/members/representatives/warringah/tony_abbott/policies/23", params: {}
    expect(response).to redirect_to "/people/representatives/warringah/tony_abbott/policies/23"
  end

  it do
    get "/members/representatives/warringah/tony_abbott/friends", params: {}
    expect(response).to redirect_to "/people/representatives/warringah/tony_abbott/friends"
  end

  it do
    get "/members/representatives/warringah/tony_abbott/divisions", params: {}
    expect(response).to redirect_to "/people/representatives/warringah/tony_abbott/divisions"
  end

  it do
    get "/members/representatives/warringah/tony_abbott/divisions/2006-12-06/3", params: {}
    expect(response).to redirect_to "/people/representatives/warringah/tony_abbott/divisions/2006-12-06/3"
  end

  it do
    get "/policies/3/detail", params: {}
    expect(response).to redirect_to("/policies/3")
  end

  it do
    get "/people/representatives/warringah", params: {}
    expect(response).to redirect_to "/people/representatives"
  end

  it do
    get "/parties/liberal_party/divisions", params: {}
    expect(response).to redirect_to "/divisions"
  end

  it do
    get "/parties/liberal_party/divisions/representatives", params: {}
    expect(response).to redirect_to "/divisions/representatives"
  end

  context "with Barnaby Joyce" do
    before do
      Person.create(id: 10350, large_image_url: "https://www.openaustralia.org.au/images/mpsL/10350.jpg")
      Member.create(id: 664, gid: "uk.org.publicwhip/member/664", source_gid: "",
                    first_name: "Barnaby", last_name: "Joyce", title: "", person_id: 10350,
                    party: "National Party",
                    house: "representatives", constituency: "New England",
                    entered_house: "2013-09-07", left_house: "9999-12-31")
      Member.create(id: 100114, gid: "uk.org.publicwhip/lord/100114", source_gid: "",
                    first_name: "Barnaby", last_name: "Joyce", title: "", person_id: 10350,
                    party: "National Party",
                    house: "senate", constituency: "Queensland",
                    entered_house: "2005-07-01", left_house: "2013-08-08")

      Electorate.create(id: 143, name: "New England", main_name: true)
    end

    it "redirects to the senator's page even if the id param incorrectly identifies a member as a senator and vice versa" do
      # Barnaby has been set up above as a member and a senator.
      # Let's refer to his senator record but incorrectly using `member` instead of `lord`
      get "/mp.php?id=uk.org.publicwhip/member/100114", params: {}
      expect(response).to redirect_to "/mp.php?house=senate&mpc=Queensland&mpn=Barnaby_Joyce"
    end
  end

  it "404s with an unknown person" do
    get "/mp.php?mpn=Foo_Bar", params: {}
    expect(response.status).to eq 404
  end
end

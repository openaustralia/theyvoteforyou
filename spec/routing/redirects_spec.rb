# frozen_string_literal: true

require "spec_helper"

describe "routing redirects", type: :request do
  fixtures :all

  it "/account/changepass.php -> /account/edit" do
    get "/account/changepass.php", params: {}
    expect(response).to redirect_to("/users/edit")
  end

  it "/account/changeemail.php -> /account/edit" do
    get "/account/changeemail.php", params: {}
    expect(response).to redirect_to("/users/edit")
  end

  it "/policies.php -> /policies" do
    get "/policies.php", params: {}
    expect(response).to redirect_to("/policies")
  end

  it "/policy.php?id=2 -> /policies/2" do
    get "/policy.php?id=2", params: {}
    expect(response).to redirect_to("/policies/2")
  end

  it "/policy.php?id=3&display=motions -> /policies/3/detail" do
    get "/policy.php?id=3&display=motions", params: {}
    expect(response).to redirect_to("/policies/3/detail")
  end

  it "/policy.php?display=editdefinition&id=1 -> /policies/1/edit" do
    get "/policy.php?display=editdefinition&id=1", params: {}
    expect(response).to redirect_to("/policies/1/edit")
  end

  it "/account/addpolicy.php -> /policies/new" do
    get "/account/addpolicy.php", params: {}
    expect(response).to redirect_to("/policies/new")
  end

  it "/mp.php?display=allvotes&dmp=1&house=senate&mpc=Tasmania&mpn=Eric_Abetz -> /mp.php?dmp=1&house=senate&mpc=Tasmania&mpn=Eric_Abetz" do
    get "/mp.php?display=allvotes&dmp=1&house=senate&mpc=Tasmania&mpn=Eric_Abetz", params: {}
    expect(response).to redirect_to("/mp.php?dmp=1&house=senate&mpc=Tasmania&mpn=Eric_Abetz")
  end

  it do
    get "/mps.php?house=all&sort=rebellions", params: {}
    expect(response).to redirect_to("/people/representatives?sort=rebellions")
  end

  it do
    get "/mps.php?house=representatives&sort=lastname", params: {}
    expect(response).to redirect_to("/people/representatives")
  end

  # Test that we don't need to get redirected twice
  it do
    get "/mps.php?house=all&sort=lastname", params: {}
    expect(response).to redirect_to("/people/representatives")
  end

  it do
    get "/mps.php?sort=rebellions", params: {}
    expect(response).to redirect_to("/people/representatives?sort=rebellions")
  end

  it "/mp.php?mpid=1&dmp=1 -> /mp.php?house=representatives&mpc=Warringah&mpn=Tony_Abbott&dmp=1" do
    get "/mp.php?mpid=1&dmp=1", params: {}
    expect(response).to redirect_to("/mp.php?dmp=1&house=representatives&mpc=Warringah&mpn=Tony_Abbott")
  end

  # showall=yes means the same thing as display=allvotes. allvotes has been removed in favour of everyvote
  it "/mp.php?house=representatives&mpc=Warringah&mpn=Tony_Abbott&showall=yes -> /mp.php?display=everyvote&house=representatives&mpc=Warringah&mpn=Tony_Abbott" do
    get "/mp.php?house=representatives&mpc=Warringah&mpn=Tony_Abbott&showall=yes", params: {}
    expect(response).to redirect_to("/mp.php?display=everyvote&house=representatives&mpc=Warringah&mpn=Tony_Abbott")
  end

  it "/mp.php?display=allvotes&id=uk.org.publicwhip/member/1 -> /mp.php?display=allvotes&house=representatives&mpc=Warringah&mpn=Tony_Abbott" do
    get "/mp.php?display=allvotes&id=uk.org.publicwhip/member/1", params: {}
    expect(response).to redirect_to("/mp.php?display=allvotes&house=representatives&mpc=Warringah&mpn=Tony_Abbott")
  end

  it "/mp.php?display=summary&house=representatives&mpc=Warringah&mpn=Tony_Abbott -> /mp.php?house=representatives&mpc=Warringah&mpn=Tony_Abbott" do
    get "/mp.php?display=summary&house=representatives&mpc=Warringah&mpn=Tony_Abbott", params: {}
    expect(response).to redirect_to("/mp.php?house=representatives&mpc=Warringah&mpn=Tony_Abbott")
  end

  describe "constituency redirect to base url" do
    it do
      get "/mp.php?display=allvotes&house=representatives&mpc=Bennelong", params: {}
      expect(response).to redirect_to "/mp.php?house=representatives&mpc=Bennelong"
    end

    it do
      get "/mp.php?dmp=1&house=representatives&mpc=Bennelong", params: {}
      expect(response).to redirect_to "/mp.php?house=representatives&mpc=Bennelong"
    end
  end

  it do
    get "/mp.php?house=representatives&mpc=Warringah", params: {}
    expect(response).to redirect_to "/members/representatives/warringah"
  end

  it do
    get "/mps.php?house=representatives&sort=party", params: {}
    expect(response).to redirect_to "/members/representatives?sort=party"
  end

  it do
    get "/mps.php?house=senate", params: {}
    expect(response).to redirect_to "/members/senate"
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
    get "/division.php?date=2014-09-04&display=policies&house=senate&number=4&sort=vote&dmp=1", params: {}
    expect(response).to redirect_to "/division.php?date=2014-09-04&display=policies&dmp=1&house=senate&number=4"
  end

  it do
    get "/division.php?date=2014-09-04&display=policies&number=3&dmp=1", params: {}
    expect(response).to redirect_to "/division.php?date=2014-09-04&display=policies&dmp=1&house=representatives&number=3"
  end

  it do
    get "/divisions.php?house=senate&rdisplay2=rebels&rdisplay=2010", params: {}
    expect(response).to redirect_to "/divisions.php?house=senate&rdisplay=2010&sort=rebellions"
  end

  it do
    get "/division.php?date=2014-09-04&house=senate&mpc=Senate&mpn=Christine_Milne&number=4", params: {}
    expect(response).to redirect_to "/division.php?date=2014-09-04&house=senate&mpc=Tasmania&mpn=Christine_Milne&number=4"
  end

  it do
    get "/division.php?date=2014-09-04&house=senate&number=4&display=allpossible", params: {}
    expect(response).to redirect_to "/division.php?date=2014-09-04&house=senate&number=4"
  end

  it do
    get "/division.php?date=2014-09-04&house=senate&number=4&display=allvotes", params: {}
    expect(response).to redirect_to "/division.php?date=2014-09-04&house=senate&number=4"
  end

  it do
    get "/division.php?date=2014-09-04&house=representatives&number=3", params: {}
    expect(response).to redirect_to "/divisions/representatives/2014-09-04/3"
  end

  it do
    get "/division.php?date=2014-09-04&house=senate&mpc=Tasmania&mpn=Eric_Abetz&number=4", params: {}
    expect(response).to redirect_to "/members/senate/tasmania/eric_abetz/divisions/2014-09-04/4"
  end

  it do
    get "/division.php?date=2014-09-04&display=policies&house=senate&number=4", params: {}
    expect(response).to redirect_to "/divisions/senate/2014-09-04/4/policies"
  end

  it do
    get "/division.php?date=2014-09-04&display=policies&house=senate&number=4&dmp=1", params: {}
    expect(response).to redirect_to "/divisions/senate/2014-09-04/4/policies/1"
  end

  it do
    get "/account/wiki.php?date=2014-09-04&house=senate&number=4&rr=%2Fdivisions%2Fsenate%2F2014-09-04%2F4&type=motion", params: {}
    expect(response).to redirect_to "/divisions/senate/2014-09-04/4/edit"
  end

  it do
    get "/edits.php?date=2014-09-04&house=senate&number=4&type=motion", params: {}
    expect(response).to redirect_to "/divisions/senate/2014-09-04/4/history"
  end

  it do
    get "/index.php", params: {}
    expect(response).to redirect_to "/"
  end

  it do
    get "/faq.php#motionedit", params: {}
    expect(response).to redirect_to "/help/faq"
  end

  it do
    get "/search.php?query=foo+bar", params: {}
    expect(response).to redirect_to "/search?query=foo+bar"
  end

  it do
    get "/search.php", params: {}
    expect(response).to redirect_to "/search"
  end

  it do
    get "/project/data.php", params: {}
    expect(response).to redirect_to "/help/data"
  end

  it do
    get "/project/research.php", params: {}
    expect(response).to redirect_to "/help/research"
  end

  it do
    get "/divisions.php?house=representatives&rdisplay2=Liberal+Party_party&rdisplay=2010", params: {}
    expect(response).to redirect_to "/parties/liberal_party/divisions/representatives?rdisplay=2010"
  end

  it do
    get "/divisions.php?house=representatives&rdisplay2=Liberal+Party_party", params: {}
    expect(response).to redirect_to "/parties/liberal_party/divisions/representatives"
  end

  it do
    get "/divisions.php?house=representatives&rdisplay2=Liberal+Party_party&sort=rebellions", params: {}
    expect(response).to redirect_to "/parties/liberal_party/divisions/representatives?sort=rebellions"
  end

  it do
    get "/divisions.php?house=representatives&rdisplay=2010&sort=rebellions", params: {}
    expect(response).to redirect_to "/divisions/representatives/2010?sort=rebellions"
  end

  it do
    get "/divisions.php?rdisplay=2010&sort=rebellions", params: {}
    expect(response).to redirect_to "/divisions/all/2010?sort=rebellions"
  end

  it do
    get "/divisions.php?rdisplay=all&house=representatives&sort=rebellions", params: {}
    expect(response).to redirect_to "/divisions/representatives?sort=rebellions"
  end

  it do
    get "/divisions.php?house=representatives", params: {}
    expect(response).to redirect_to "/divisions/representatives"
  end

  it do
    get "/divisions.php", params: {}
    expect(response).to redirect_to "/divisions"
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
end

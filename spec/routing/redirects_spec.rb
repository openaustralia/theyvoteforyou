# frozen_string_literal: true

require "spec_helper"

describe "routing redirects", type: :request do
  fixtures :all

  # This is an old url still being used by openaustralia.org.au
  it do
    create(:policy, id: 1)
    create(:member, id: 1, first_name: "Tony", last_name: "Abbott", constituency: "Warringah", house: "representatives")
    get "/mp.php?mpid=1&dmp=1"
    expect(response).to redirect_to "/people/representatives/warringah/tony_abbott/policies/1"
  end

  # This is an old url still being used by openaustralia.org.au
  it do
    create(:member, id: 1, gid: "uk.org.publicwhip/member/1", first_name: "Tony", last_name: "Abbott",
                    constituency: "Warringah", house: "representatives")
    get "/mp.php?id=uk.org.publicwhip/member/1"
    expect(response).to redirect_to "/people/representatives/warringah/tony_abbott"
  end

  # This is an old style php url which we have removed support for
  it do
    expect do
      get "/mp.php?dmp=38&house=representatives&mpc=Wakefield&mpn=Nick_Champion"
    end.to raise_error(ActiveRecord::RecordNotFound)
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
      get "/mp.php?id=uk.org.publicwhip/member/100114"
      expect(response).to redirect_to "/people/senate/queensland/barnaby_joyce"
    end
  end

  it do
    get "/members/representatives/lilley/wayne_swan/policies/3/full"
    expect(response).to redirect_to "/members/representatives/lilley/wayne_swan/policies/3"
  end

  it do
    get "/members"
    expect(response).to redirect_to "/people"
  end

  it do
    get "/members/representatives"
    expect(response).to redirect_to "/people/representatives"
  end

  it do
    get "/members?sort=attendance"
    expect(response).to redirect_to "/people?sort=attendance"
  end

  it do
    get "/members/representatives?sort=attendance"
    expect(response).to redirect_to "/people/representatives?sort=attendance"
  end

  it do
    get "/members/representatives/melbourne"
    expect(response).to redirect_to "/people/representatives/melbourne"
  end

  it do
    get "/members/representatives/warringah/tony_abbott"
    expect(response).to redirect_to "/people/representatives/warringah/tony_abbott"
  end

  it do
    get "/members/representatives/warringah/tony_abbott/policies/23"
    expect(response).to redirect_to "/people/representatives/warringah/tony_abbott/policies/23"
  end

  it do
    get "/members/representatives/warringah/tony_abbott/friends"
    expect(response).to redirect_to "/people/representatives/warringah/tony_abbott/friends"
  end

  it do
    get "/members/representatives/warringah/tony_abbott/divisions"
    expect(response).to redirect_to "/people/representatives/warringah/tony_abbott/divisions"
  end

  it do
    get "/members/representatives/warringah/tony_abbott/divisions/2006-12-06/3"
    expect(response).to redirect_to "/people/representatives/warringah/tony_abbott/divisions/2006-12-06/3"
  end

  it do
    get "/policies/3/detail"
    expect(response).to redirect_to("/policies/3")
  end

  it do
    get "/people/representatives/warringah"
    expect(response).to redirect_to "/people/representatives"
  end

  it do
    get "/parties/liberal_party/divisions"
    expect(response).to redirect_to "/divisions"
  end

  it do
    get "/parties/liberal_party/divisions/representatives"
    expect(response).to redirect_to "/divisions/representatives"
  end

  it do
    get "/divisions"
    expect(response).to redirect_to "/divisions/all"
  end

  it do
    get "/divisions", params: { sort: "rebellions" }
    expect(response).to redirect_to "/divisions/all?sort=rebellions"
  end

  it do
    get "/divisions", params: { sort: "subject" }
    expect(response).to redirect_to "/divisions/all?sort=subject"
  end

  it do
    get "/divisions", params: { sort: "turnout" }
    expect(response).to redirect_to "/divisions/all?sort=turnout"
  end

  it do
    get "/divisions/senate/2009-11-25/8/policies/1"
    expect(response).to redirect_to "/divisions/senate/2009-11-25/8/policies"
  end

  it do
    get "/divisions/senate/2009-11-25/8/policies/2"
    expect(response).to redirect_to "/divisions/senate/2009-11-25/8/policies"
  end
end

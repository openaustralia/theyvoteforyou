require 'spec_helper'

describe "routing redirects", :type => :request do
  fixtures :all

  it "/account/changepass.php -> /account/edit" do
    get "/account/changepass.php"
    expect(response).to redirect_to("/users/edit")
  end

  it "/account/changeemail.php -> /account/edit" do
    get "/account/changeemail.php"
    expect(response).to redirect_to("/users/edit")
  end

  it "/policies.php -> /policies" do
    get "/policies.php"
    expect(response).to redirect_to("/policies")
  end

  it "/policy.php?id=2 -> /policies/2" do
    get "/policy.php?id=2"
    expect(response).to redirect_to("/policies/2")
  end

  it "/policy.php?id=3&display=motions -> /policies/3/detail" do
    get "/policy.php?id=3&display=motions"
    expect(response).to redirect_to("/policies/3/detail")
  end

  it "/policy.php?display=editdefinition&id=1 -> /policies/1/edit" do
    get "/policy.php?display=editdefinition&id=1"
    expect(response).to redirect_to("/policies/1/edit")
  end

  it "/account/addpolicy.php -> /policies/new" do
    get "/account/addpolicy.php"
    expect(response).to redirect_to("/policies/new")
  end

  it "/mp.php?display=allvotes&dmp=1&house=senate&mpc=Tasmania&mpn=Eric_Abetz -> /mp.php?dmp=1&house=senate&mpc=Tasmania&mpn=Eric_Abetz" do
    get "/mp.php?display=allvotes&dmp=1&house=senate&mpc=Tasmania&mpn=Eric_Abetz"
    expect(response).to redirect_to("/mp.php?dmp=1&house=senate&mpc=Tasmania&mpn=Eric_Abetz")
  end

  it "/mps.php?house=all&sort=rebellions -> /mps.php?house=representatives&sort=rebellions" do
    get "/mps.php?house=all&sort=rebellions"
    expect(response).to redirect_to("/mps.php?house=representatives&sort=rebellions")
  end

  it "/mps.php?house=representatives&sort=lastname -> /mps.php?house=representatives" do
    get "/mps.php?house=representatives&sort=lastname"
    expect(response).to redirect_to("/mps.php?house=representatives")
  end

  # Test that we don't need to get redirected twice
  it "/mps.php?house=all&sort=lastname -> /mps.php?house=representatives" do
    get "/mps.php?house=all&sort=lastname"
    expect(response).to redirect_to("/mps.php?house=representatives")
  end

  it "/mps.php?sort=rebellions -> /mps.php?house=representatives&sort=rebellions" do
    get "/mps.php?sort=rebellions"
    expect(response).to redirect_to("/mps.php?house=representatives&sort=rebellions")
  end

  it "/mp.php?mpid=1&dmp=1 -> /mp.php?house=representatives&mpc=Warringah&mpn=Tony_Abbott&dmp=1" do
    get "/mp.php?mpid=1&dmp=1"
    expect(response).to redirect_to("/mp.php?dmp=1&house=representatives&mpc=Warringah&mpn=Tony_Abbott")
  end

  # showall=yes means the same thing as display=allvotes
  it "/mp.php?house=representatives&mpc=Warringah&mpn=Tony_Abbott&showall=yes -> /mp.php?display=allvotes&house=representatives&mpc=Warringah&mpn=Tony_Abbott" do
    get "/mp.php?house=representatives&mpc=Warringah&mpn=Tony_Abbott&showall=yes"
    expect(response).to redirect_to("/mp.php?display=allvotes&house=representatives&mpc=Warringah&mpn=Tony_Abbott")
  end

  it "/mp.php?display=allvotes&id=uk.org.publicwhip/member/1 -> /mp.php?display=allvotes&house=representatives&mpc=Warringah&mpn=Tony_Abbott" do
    get "/mp.php?display=allvotes&id=uk.org.publicwhip/member/1"
    expect(response).to redirect_to("/mp.php?display=allvotes&house=representatives&mpc=Warringah&mpn=Tony_Abbott")
  end

  it "/mp.php?display=summary&house=representatives&mpc=Warringah&mpn=Tony_Abbott -> /mp.php?house=representatives&mpc=Warringah&mpn=Tony_Abbott" do
    get "/mp.php?display=summary&house=representatives&mpc=Warringah&mpn=Tony_Abbott"
    expect(response).to redirect_to("/mp.php?house=representatives&mpc=Warringah&mpn=Tony_Abbott")
  end

  describe "constituency redirect to base url" do
    it do
      get "/mp.php?display=allvotes&house=representatives&mpc=Bennelong"
      expect(response).to redirect_to "/mp.php?house=representatives&mpc=Bennelong"
    end

    it do
      get "/mp.php?dmp=1&house=representatives&mpc=Bennelong"
      expect(response).to redirect_to "/mp.php?house=representatives&mpc=Bennelong"
    end
  end
end

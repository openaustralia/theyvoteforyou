require 'spec_helper'

describe "routing redirects", :type => :request do
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

  it "/mps.php?house=all&parliament=2007&sort=rebellions -> /mps.php?house=representatives&parliament=2007&sort=rebellions" do
    get "/mps.php?house=all&parliament=2007&sort=rebellions"
    expect(response).to redirect_to("/mps.php?house=representatives&parliament=2007&sort=rebellions")
  end

  it "/mps.php?house=representatives&parliament=2010&sort=lastname -> /mps.php?house=representatives&parliament=2010" do
    get "/mps.php?house=representatives&parliament=2010&sort=lastname"
    expect(response).to redirect_to("/mps.php?house=representatives&parliament=2010")
  end

  # Test that we don't need to get redirected twice
  it "/mps.php?house=all&sort=lastname -> /mps.php?house=representatives" do
    get "/mps.php?house=all&sort=lastname"
    expect(response).to redirect_to("/mps.php?house=representatives")
  end
end

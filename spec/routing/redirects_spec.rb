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
end

# frozen_string_literal: true

require "spec_helper"

describe "routing redirects", type: :request do
  fixtures :all

  # This is an old url still being used by openaustralia.org.au
  it do
    get "/mp.php?mpid=1&dmp=1", params: {}
    expect(response).to redirect_to "/people/representatives/warringah/tony_abbott/policies/1"
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
end

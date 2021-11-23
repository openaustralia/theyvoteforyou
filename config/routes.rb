# frozen_string_literal: true

Publicwhip::Application.routes.draw do
  devise_for :users, controllers: { registrations: "registrations", confirmations: "confirmations" }

  # These ancient php redirects are still needed to support links from openaustralia.org.au
  get "mp.php" => "members#show_redirect"

  # Redirects
  get "/members/:house/:mpc/:mpn/policies/:id/full" => redirect("/members/%{house}/%{mpc}/%{mpn}/policies/%{id}")
  get "/members" => redirect { |_p, r|
    if r.query_parameters["sort"]
      "/people?sort=#{r.query_parameters['sort']}"
    else
      "/people"
    end
  }, as: nil
  get "/members/:house" => redirect { |p, r|
    if r.query_parameters["sort"]
      "/people/#{p[:house]}?sort=#{r.query_parameters['sort']}"
    else
      "/people/#{p[:house]}"
    end
  }
  get "/members/:house/:mpc" => redirect("/people/%{house}/%{mpc}")
  get "/members/:house/:mpc/:mpn" => redirect("/people/%{house}/%{mpc}/%{mpn}")
  get "/members/:house/:mpc/:mpn/policies/:id" => redirect("/people/%{house}/%{mpc}/%{mpn}/policies/%{id}")
  get "/members/:house/:mpc/:mpn/friends" => redirect("/people/%{house}/%{mpc}/%{mpn}/friends")
  get "/members/:house/:mpc/:mpn/divisions" => redirect("/people/%{house}/%{mpc}/%{mpn}/divisions")
  get "/members/:house/:mpc/:mpn/divisions/:date/:number" => redirect("/people/%{house}/%{mpc}/%{mpn}/divisions/%{date}/%{number}")
  get "/policies/:id/detail" => redirect("/policies/%{id}")
  get "/people/:house/:mpc" => redirect("/people/%{house}")
  get "/parties/:party/divisions/:house" => redirect("/divisions/%{house}")
  get "/parties/:party/divisions" => redirect("/divisions")

  #################
  #  Main routes  #
  #################

  root "home#index"

  get "search" => "home#search", as: :search
  get "about" => "home#about", as: :about
  get "history" => "home#history", as: :history

  get "/people(/:house)" => "members#index", as: :members
  get "/people/:house/:mpc/:mpn" => "members#show", as: :member
  get "/people/:house/:mpc/:mpn/policies/:id" => "members#policy", as: :member_policy
  get "/people/:house/:mpc/:mpn/friends" => "members#friends", as: :friends_member
  get "/people/:house/:mpc/:mpn/compare/:mpc2/:mpn2" => "members#compare", as: :compare_member
  get "/people/:house/:mpc/:mpn/divisions" => "divisions#index", as: :member_divisions
  get "/people/:house/:mpc/:mpn/divisions/:date" => "divisions#index"
  get "/people/:house/:mpc/:mpn/divisions/:date/:number" => "divisions#show", as: :member_division

  get "/divisions" => "divisions#index", as: :divisions
  get "/divisions/:house" => "divisions#index"
  get "/divisions/:house/:date" => "divisions#index"

  get "/divisions/:house/:date/:number" => "divisions#show", as: :division
  post "/divisions/:house/:date/:number" => "divisions#update"
  get "/divisions/:house/:date/:number/policies" => "divisions#show_policies", as: :division_policies
  post "/divisions/:house/:date/:number/policies/create" => "divisions#create_policy_division", as: :create_policy_division
  patch "/divisions/:house/:date/:number/policies/:policy_id" => "divisions#update_policy_division", as: :update_policy_division
  delete "/divisions/:house/:date/:number/policies/:policy_id/delete" => "divisions#destroy_policy_division", as: :destroy_policy_division
  get "/divisions/:house/:date/:number/policies/:dmp" => redirect("/divisions/%{house}/%{date}/%{number}/policies")
  get "/divisions/:house/:date/:number/history" => "divisions#history", as: :history_division
  get "/divisions/:house/:date/:number/edit" => "divisions#edit", as: :edit_division

  resources :policies, except: :destroy do
    get "drafts", on: :collection
    member do
      get "history"
      post "watch"
    end
  end

  get "users/stats" => "users#stats", as: :user_stats
  get "users/welcome" => "users#welcome", as: :user_welcome
  get "users/confirm" => "users#confirm", as: :user_confirm
  get "users/:id" => "users#show", as: :user
  get "users/:id/subscriptions" => "users#subscriptions", as: :user_subscriptions

  get "feeds/mp-info" => "feeds#mp_info", as: :mp_info_feed
  get "feeds/mpdream-info" => "feeds#mpdream_info", as: :mpdream_info_feed

  namespace :help do
    get "faq"
    get "data"
    get "research"
    get "licencing"
    get "style-guide", action: :style_guide
  end

  ## API routes

  namespace :api do
    namespace :v1 do
      resources :people, only: %i[index show]
      resources :policies, only: %i[index show]
      resources :divisions, only: %i[index show]
    end
  end

  ## Error pages
  get "/404", to: "home#error404"
  get "/500", to: "home#error500"
end

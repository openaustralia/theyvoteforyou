Publicwhip::Application.routes.draw do
  devise_for :users
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # Redirects
  get 'policies.php' => redirect('/policies')
  get 'policy.php' => redirect {|p,r| "/policies/#{r.query_parameters['id']}/edit"},
    constraints: lambda { |request| request.query_parameters["display"] == "editdefinition"}
  get 'policy.php' => redirect {|p,r| "/policies/#{r.query_parameters['id']}/detail"},
    constraints: lambda { |request| request.query_parameters["display"] == "motions"}
  get "policy.php" => redirect {|p,r| "/policies/#{r.query_parameters['id']}"}
  get '/account/addpolicy.php' => redirect("/policies/new")

  get '/account/changepass.php' => redirect('/users/edit')
  get '/account/changeemail.php' => redirect('/users/edit')
  get '/account/settings.php' => redirect('/users/edit')

  get 'mps.php' => 'members#index_redirect',
    constraints: lambda {|r| r.query_parameters["house"] == "all" || r.query_parameters["house"].nil? || r.query_parameters["sort"] == "lastname" || r.query_parameters["parliament"]}
  get 'mps.php' => redirect {|p,r|
    if r.query_parameters["sort"]
      "/members/#{r.query_parameters['house']}?sort=#{r.query_parameters['sort']}"
    else
      "/members/#{r.query_parameters['house']}"
    end
  }
  get 'mp.php' => 'members#show_redirect',
    constraints: lambda {|r| r.query_parameters["mpid"] || r.query_parameters["id"]}
  get 'mp.php' => 'electorates#show_redirect',
    constraints: lambda {|r| r.query_parameters["mpn"].nil? && (r.query_parameters["display"] || r.query_parameters["dmp"] || r.query_parameters["house"].nil?)}
  get 'mp.php' => redirect{|p,r| "/members/#{r.query_parameters['house']}/#{r.query_parameters['mpc'].downcase}"},
    constraints: lambda {|r| r.query_parameters["mpn"].nil?}
  get 'mp.php' => 'members#show_redirect',
    constraints: lambda {|r| r.query_parameters["dmp"] && r.query_parameters["display"] == "allvotes"}
  get 'mp.php' => 'members#show_redirect',
    constraints: lambda {|r| r.query_parameters["display"] == "summary" || r.query_parameters["display"] == "alldreams" || r.query_parameters["display"] == "allvotes" || r.query_parameters["showall"] == "yes"}
  get 'mp.php' => 'members#show_redirect',
    constraints: lambda {|r| r.query_parameters["mpc"] == "Senate" || r.query_parameters["mpc"].nil? || r.query_parameters["house"].nil?}
  get 'mp.php' => redirect{|p,r|
    "/members/#{r.query_parameters['house']}/#{r.query_parameters['mpc'].downcase}/#{r.query_parameters['mpn'].downcase}/friends"
  }, constraints: lambda {|r| r.query_parameters["display"] == "allfriends" && r.query_parameters[:dmp].nil?}
  get 'mp.php' => redirect{|p,r|
    "/members/#{r.query_parameters['house']}/#{r.query_parameters['mpc'].downcase}/#{r.query_parameters['mpn'].downcase}/divisions"
  }, constraints: lambda {|r| r.query_parameters["display"] == "everyvote" && r.query_parameters[:dmp].nil?}
  get 'mp.php' => redirect{|p,r|
    "/members/#{r.query_parameters['house']}/#{r.query_parameters['mpc'].downcase}/#{r.query_parameters['mpn'].downcase}/policies/#{r.query_parameters['dmp']}/full"
  }, constraints: lambda {|r| r.query_parameters["display"] == "motions" && r.query_parameters[:dmp]}
  get 'mp.php' => redirect{|p,r|
    result = "/members/#{r.query_parameters['house']}/#{r.query_parameters['mpc'].downcase}/#{r.query_parameters['mpn'].downcase}"
    result += "/policies/#{r.query_parameters['dmp']}" if r.query_parameters['dmp']
    queries = []
    queries << "display=#{r.query_parameters['display']}" if r.query_parameters["display"]
    result += "?" + queries.join("&") unless queries.empty?
    result
  }
  get 'divisions.php' => 'divisions#index_redirect',
    constraints: lambda {|r| r.query_parameters["rdisplay2"] == "rebels"}
  get 'division.php' => 'divisions#show_redirect',
    constraints: lambda {|r| r.query_parameters["sort"]}
  get 'division.php' => 'divisions#show_redirect',
    constraints: lambda {|r| r.query_parameters["display"] == "allvotes" || r.query_parameters["display"] == "allpossible"}
  get 'division.php' => 'divisions#show_redirect',
    constraints: lambda {|r| r.query_parameters["house"].nil? }
  get 'division.php' => redirect{|p,r| "/divisions/#{r.query_parameters['house']}/#{r.query_parameters['date']}/#{r.query_parameters['number']}/policies/#{r.query_parameters['dmp']}"},
    constraints: lambda {|r| r.query_parameters["display"] == "policies" && r.query_parameters["dmp"]}
  get 'division.php' => redirect{|p,r| "/divisions/#{r.query_parameters['house']}/#{r.query_parameters['date']}/#{r.query_parameters['number']}/policies"},
    constraints: lambda {|r| r.query_parameters["display"] == "policies"}
  get 'division.php' => 'divisions#show_redirect',
    constraints: lambda {|r| r.query_parameters["mpc"] == "Senate"}
  get 'division.php' => redirect{|p,r| "/divisions/#{r.query_parameters['house']}/#{r.query_parameters['date']}/#{r.query_parameters['number']}"},
    constraints: lambda {|r| r.query_parameters["display"].nil? && r.query_parameters["mpn"].nil?}
  get 'division.php' => redirect{|p,r| "/members/#{r.query_parameters['house']}/#{r.query_parameters['mpc'].downcase}/#{r.query_parameters['mpn'].downcase}/divisions/#{r.query_parameters['date']}/#{r.query_parameters['number']}"},
    constraints: lambda {|r| r.query_parameters["mpn"] && r.query_parameters["mpc"]}
  get 'edits.php' => redirect{|p,r| "/divisions/#{r.query_parameters['house']}/#{r.query_parameters['date']}/#{r.query_parameters['number']}/history"}
  get 'account/wiki.php' => redirect{|p,r| "/divisions/#{r.query_parameters['house']}/#{r.query_parameters['date']}/#{r.query_parameters['number']}/edit"}
  get 'index.php' => redirect("/")
  # Unfortunately without resorting to something like js not possible to preserve anchor on redirect
  get 'faq.php' => redirect{|p,r| "/help/faq"}
  get 'search.php' => redirect{|p,r|
    if r.query_parameters['query']
      "/search?query=#{Rack::Utils.escape(r.query_parameters['query'])}"
    else
      "/search"
    end
  }
  get 'project/code.php', to: redirect('https://github.com/openaustralia/publicwhip/')
  get 'project/data.php' => redirect("/help/data")
  get 'project/research.php' => redirect("/help/research")

  get 'divisions.php' => redirect{|p,r|
    if r.query_parameters['party']
      party = r.query_parameters['party']
    else
      party = r.query_parameters['rdisplay2'].gsub('_party', '')
    end
    result = "/parties/#{party.downcase.gsub(' ', '_')}/divisions/#{r.query_parameters['house']}"
    q = []
    q << "rdisplay=#{r.query_parameters['rdisplay']}" if r.query_parameters['rdisplay']
    q << "sort=#{r.query_parameters['sort']}" if r.query_parameters['sort']
    result += "?" + q.join("&") unless q.empty?
    result
  }, constraints: lambda {|r| r.query_parameters['rdisplay2'] || r.query_parameters['party']}
  get 'divisions.php' => redirect{|p,r|
    result = "/divisions"
    result += "/#{r.query_parameters['house']}" if r.query_parameters['house']
    q = []
    q << "rdisplay=#{r.query_parameters['rdisplay']}" if r.query_parameters['rdisplay']
    q << "sort=#{r.query_parameters['sort']}" if r.query_parameters['sort']
    result += "?" + q.join("&") unless q.empty?
    result
  }

  #################
  #  Main routes  #
  #################

  root 'home#index'

  get 'search' => 'home#search', as: :search
  get 'about' => 'home#about', as: :about
  get 'history' => 'home#history', as: :history

  get '/members(/:house)' => 'members#index', as: :members
  get '/members/:house/:mpc' => 'electorates#show', as: :electorate
  get '/members/:house/:mpc/:mpn' => 'members#show', as: :member
  get '/members/:house/:mpc/:mpn/policies/:id' => 'policies#show', as: :member_policy
  get '/members/:house/:mpc/:mpn/policies/:id/full' => 'policies#full', as: :full_member_policy
  get '/members/:house/:mpc/:mpn/friends' => 'members#friends', as: :friends_member
  get '/members/:house/:mpc/:mpn/divisions' => 'divisions#index', as: :member_divisions
  get '/members/:house/:mpc/:mpn/divisions/:date/:number' => 'divisions#show', as: :member_division

  get '/divisions' => 'divisions#index', as: :divisions
  get '/divisions/:house' => 'divisions#index'
  get '/parties/:party/divisions/:house' => 'divisions#index'
  get '/parties/:party/divisions' => 'divisions#index', as: :party_divisions

  get '/divisions/:house/:date/:number' => 'divisions#show', as: :division
  post '/divisions/:house/:date/:number' => 'divisions#update'
  get '/divisions/:house/:date/:number/policies' => 'divisions#show_policies', as: :division_policies
  post '/divisions/:house/:date/:number/policies/create' => 'divisions#create_policy_division', as: :create_policy_division
  patch '/divisions/:house/:date/:number/policies/:policy_id' => 'divisions#update_policy_division', as: :update_policy_division
  delete '/divisions/:house/:date/:number/policies/:policy_id/delete' => 'divisions#destroy_policy_division', as: :destroy_policy_division
  get '/divisions/:house/:date/:number/policies/:dmp' => redirect("/divisions/%{house}/%{date}/%{number}/policies")
  get '/divisions/:house/:date/:number/history' => 'divisions#history', as: :history_division
  get '/divisions/:house/:date/:number/edit' => 'divisions#edit', as: :edit_division

  resources :policies, except: :destroy do
    member do
      get 'detail'
      get 'history'
    end
  end

  get 'users/:id' => 'users#show', as: :user

  get 'feeds/mp-info' => 'feeds#mp_info', as: :mp_info_feed
  get 'feeds/mpdream-info' => 'feeds#mpdream_info', as: :mpdream_info_feed

  namespace :help do
    get 'faq'
    get 'data'
    get 'research'
    get 'licencing'
  end

  ## API routes

  namespace :api do
    resources :people, only: :index
  end

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end

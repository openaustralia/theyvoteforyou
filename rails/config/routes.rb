Publicwhip::Application.routes.draw do
  devise_for :users
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  root 'home#index'

  get 'index.php' => 'home#index'
  get 'faq.php' => 'home#faq', as: :help
  get 'search.php' => 'home#search'

  get 'mps.php' => 'members#index'
  get 'mp.php' => 'members#show'

  get 'divisions.php' => 'divisions#index'
  get 'division.php' => 'divisions#show'
  post 'division.php' => 'divisions#add_policy_vote'

  get 'edits.php' => 'edits#show'

  get 'policies.php' => 'policies#index', as: :policies
  get 'policy.php' => 'policies#show', as: :policy

  post 'redir.php', to: redirect { |p, r| (r.params[:r] || r.params[:r2] || r.params[:r3]) }

  scope path: '/account' do
    match 'settings.php' => 'account#settings', via: [:get, :post]

    get 'wiki.php' => 'divisions#edit'
    post 'wiki.php' => 'divisions#update'

    get 'addpolicy.php' => 'policies#new'
    post 'addpolicy.php' => 'policies#create'
  end

  devise_scope :user do
    get '/account/logout.php' => 'devise/sessions#destroy'
    match '/account/changepass.php' => 'devise/registrations#edit', via: [:get, :post]
  end

  scope path: '/feeds' do
    get 'mp-info' => 'feeds#mp_info'
    get 'mpdream-info' => 'feeds#mpdream_info'
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

# frozen_string_literal: true

set :branch, :main
set :deploy_to, "/srv/www/production"

set :rails_env, "production"

role :app, %w[deploy@theyvoteforyou.org.au]
role :web, %w[deploy@theyvoteforyou.org.au]
role :db,  %w[deploy@theyvoteforyou.org.au]

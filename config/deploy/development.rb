# frozen_string_literal: true

set :branch, :main
set :deploy_to, "/srv/www/staging"

set :rails_env, "staging"

role :app, %w[deploy@theyvoteforyou.test]
role :web, %w[deploy@theyvoteforyou.test]
role :db,  %w[deploy@theyvoteforyou.test]

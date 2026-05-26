# frozen_string_literal: true

set :branch, ENV.fetch("STAGING_BRANCH", "main")
set :deploy_to, "/srv/www/staging"

set :rails_env, "staging"

role :app, %w[deploy@theyvoteforyou.org.au]
role :web, %w[deploy@theyvoteforyou.org.au]
role :db,  %w[deploy@theyvoteforyou.org.au]

# frozen_string_literal: true

set :branch, :main
set :deploy_to, "/srv/www/staging"

role :app, %w[deploy@theyvoteforyou.org.au]
role :web, %w[deploy@theyvoteforyou.org.au]
role :db,  %w[deploy@theyvoteforyou.org.au]

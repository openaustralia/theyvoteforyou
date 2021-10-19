# frozen_string_literal: true

set :branch, :master
set :deploy_to, "/srv/www/production"

role :app, %w[deploy@theyvoteforyou.org.au]
role :web, %w[deploy@theyvoteforyou.org.au]
role :db,  %w[deploy@theyvoteforyou.org.au]

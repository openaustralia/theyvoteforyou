set :branch, :test
set :deploy_to, "/srv/www/staging"

role :app, %w{deploy@theyvoteforyou.org.au}
role :web, %w{deploy@theyvoteforyou.org.au}
role :db,  %w{deploy@theyvoteforyou.org.au}

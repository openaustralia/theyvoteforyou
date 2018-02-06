set :branch, :test
set :deploy_to, "/srv/www/staging"

role :app, %w{deploy@ec2.theyvoteforyou.org.au}
role :web, %w{deploy@ec2.theyvoteforyou.org.au}
role :db,  %w{deploy@ec2.theyvoteforyou.org.au}

set :branch, :master
set :deploy_to, "/srv/www"

role :app, %w{deploy@ec2.theyvoteforyou.org.au}
role :web, %w{deploy@ec2.theyvoteforyou.org.au}
role :db,  %w{deploy@ec2.theyvoteforyou.org.au}

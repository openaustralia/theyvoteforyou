set :application, "publicwhip-test.openaustraliafoundation.org.au"
set :scm, :git
set :repository,  "https://github.com/openaustralia/publicwhip.git"
set :branch, :test

server "kedumba.openaustraliafoundation.org.au", :app, :web, :db, :primary => true

set :use_sudo, false
set :user, "deploy"
set :deploy_to, "/srv/www/publicwhip-test.openaustraliafoundation.org.au"

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end
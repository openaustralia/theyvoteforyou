set :application, "publicwhip-test.openaustraliafoundation.org.au"
set :scm, :git
set :deploy_via, :remote_cache
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
    # Do a graceful restart of Apache?
    # For the time being doing nothing
  end

  task :finalize_update, :except => { :no_release => true } do
    escaped_release = latest_release.to_s.shellescape
    commands = []

    commands << "ln -s -- #{shared_path}/Config.pm #{escaped_release}/loader/PublicWhip/Config.pm"
    commands << "ln -s -- #{shared_path}/config.php #{escaped_release}/website/config.php"

    run commands.join(' && ') if commands.any?
  end

end

role :app, %w{deploy@kedumba.openaustraliafoundation.org.au}
role :web, %w{deploy@kedumba.openaustraliafoundation.org.au}
role :db,  %w{deploy@kedumba.openaustraliafoundation.org.au}

set :branch, :test
set :deploy_to, "/srv/www/publicwhip-test.openaustraliafoundation.org.au"
set :rails_env, 'production'

set :linked_files, %w{php/loader/PublicWhip/Config.pm php/website/config.php config/database.yml config/secrets.yml config/newrelic.yml}

set :rvm_ruby_version, '2.0.0'

namespace :foreman do
  desc "Export the Procfile to Ubuntu's upstart scripts"
  task :export do
    on roles(:app) do
      within current_path.join('rails') do
        execute :sudo, :foreman, :export, :upstart, "/etc/init -u deploy -a publicwhip -f Procfile.production -l #{shared_path}/log --root #{current_path}"
      end
    end
  end

  desc "Start the application services"
  task :start do
    on roles(:app) do
      execute :sudo, :service, :publicwhip, :start
    end
  end

  desc "Stop the application services"
  task :stop do
    on roles(:app) do
      execute :sudo, :service, :publicwhip, :stop
    end
  end

  desc "Restart the application services"
  task :restart do
    on roles(:app) do
      execute :sudo, :service, :publicwhip, :restart
    end
  end
end

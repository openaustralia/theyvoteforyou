role :app, %w{deploy@kedumba.openaustraliafoundation.org.au}
role :web, %w{deploy@kedumba.openaustraliafoundation.org.au}
role :db,  %w{deploy@kedumba.openaustraliafoundation.org.au}

set :branch, :test
set :deploy_to, "/srv/www/publicwhip-test.openaustraliafoundation.org.au"

set :linked_files, %w{loader/PublicWhip/Config.pm website/config.php rails/config/database.yml rails/config/secrets.yml rails/config/newrelic.yml}

set :rvm_ruby_version, '2.0.0'

set :bundle_gemfile, -> { release_path.join('rails').join('Gemfile') }

namespace :deploy do
  desc 'Restart Rails application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :mkdir, "-p", release_path.join('rails/tmp/')
      execute :touch, release_path.join('rails/tmp/restart.txt')
    end
  end

  after :publishing, :restart

  desc 'Run pending Rails migrations'
  task :migrate do
    on roles(:db) do
      within current_path.join('rails') do
        with rails_env: :production do
          execute :rake, 'db:migrate'
        end
      end
    end
  end
end

namespace :foreman do
  desc "Export the Procfile to Ubuntu's upstart scripts"
  task :export do
    on roles(:app) do
      within current_path.join('rails') do
        execute :sudo, :foreman, :export, :upstart, "/etc/init -u deploy -a publicwhip -f Procfile.production -l #{shared_path}/log --root #{current_path.join('rails')}"
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

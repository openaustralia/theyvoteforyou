# frozen_string_literal: true

set :application, "theyvoteforyou.org.au"
set :repo_url, "https://github.com/openaustralia/theyvoteforyou.git"

set :rails_env, "production"

set :rvm_ruby_version, "3.4.4"

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app
# set :deploy_to, '/var/www/my_app'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, %w[config/database.yml config/settings.yml config/credentials/production.key config/newrelic.yml config/skylight.yml]

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []) + %w[log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/cards]

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

namespace :foreman do
  desc "Export the Procfile to Ubuntu's upstart scripts"
  task :export do
    on roles(:app) do
      within current_path do
        execute :sudo, :bundle, :exec, :foreman, :export, :systemd, "/etc/systemd/system -u deploy -a theyvoteforyou-#{fetch(:stage)} -f Procfile.production -l #{shared_path}/log --root #{current_path}"
      end
    end
  end

  desc "Start the application services"
  task :start do
    on roles(:app) do
      execute :systemctl, :start, "theyvoteforyou-#{fetch(:stage)}.target"
    end
  end

  desc "Stop the application services"
  task :stop do
    on roles(:app) do
      execute :sudo, :systemctl, :stop, "theyvoteforyou-#{fetch(:stage)}.target"
    end
  end

  desc "Restart the application services"
  task :restart do
    on roles(:app) do
      execute :sudo, :systemctl, :restart, "theyvoteforyou-#{fetch(:stage)}.target"
    end
  end

  # This only strictly needs to get run on the first deploy
  desc "Enable the application services"
  task :enable do
    on roles(:app) do
      execute :sudo, :systemctl, :enable, "theyvoteforyou-#{fetch(:stage)}.target"
    end
  end
end

namespace :deploy do
  desc "Restart application"
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join("tmp/restart.txt")
    end
  end

  after :publishing, :restart
  after :restart, "foreman:export"
  after "foreman:export", "foreman:enable"
  after "foreman:enable", "foreman:restart"
end

namespace :app do
  namespace :db do
    desc "Seed the database with some test values"
    task :seed do
      on roles(:app) do
        within current_path do
          execute :bundle, :exec, :rake, "db:seed", "RAILS_ENV=production"
        end
      end
    end
  end
  namespace :searchkick do
    namespace :reindex do
      desc "Reindex the search database"
      task :all do
        on roles(:app) do
          within current_path do
            execute :bundle, :exec, :rake, "searchkick:reindex:all", "RAILS_ENV=production"
          end
        end
      end
    end
  end
end

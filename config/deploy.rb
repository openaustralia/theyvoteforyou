# config valid only for Capistrano 3.1
lock '3.2.1'

set :application, 'publicwhip-test.openaustraliafoundation.org.au'
set :repo_url, 'https://github.com/openaustralia/publicwhip.git'

role :app, %w{deploy@kedumba.openaustraliafoundation.org.au}
role :web, %w{deploy@kedumba.openaustraliafoundation.org.au}
role :db,  %w{deploy@kedumba.openaustraliafoundation.org.au}

set :rails_env, 'production'

set :rvm_ruby_version, '2.0.0'

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
set :linked_files, %w{config/database.yml config/settings.yml config/secrets.yml config/newrelic.yml}

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []) + %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

namespace :foreman do
  desc "Export the Procfile to Ubuntu's upstart scripts"
  task :export do
    on roles(:app) do
      within current_path do
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

namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart
  after :restart, 'foreman:restart'
  after :updated, "newrelic:notice_deployment"
end

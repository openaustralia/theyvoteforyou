role :app, %w{deploy@kedumba.openaustraliafoundation.org.au}
role :web, %w{deploy@kedumba.openaustraliafoundation.org.au}
role :db,  %w{deploy@kedumba.openaustraliafoundation.org.au}

set :branch, :test
set :deploy_to, "/srv/www/publicwhip-test.openaustraliafoundation.org.au"

set :linked_files, %w{loader/PublicWhip/Config.pm website/config.php rails/config/database.yml rails/config/secrets.yml}

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
end

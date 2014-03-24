role :app, %w{deploy@kedumba.openaustraliafoundation.org.au}
role :web, %w{deploy@kedumba.openaustraliafoundation.org.au}
role :db,  %w{deploy@kedumba.openaustraliafoundation.org.au}

set :branch, :test
set :deploy_to, "/srv/www/publicwhip-test.openaustraliafoundation.org.au"

set :linked_files, %w{loader/PublicWhip/Config.pm website/config.php}

set :rvm_ruby_version, '2.0.0'

set :bundle_gemfile, -> { release_path.join('rails').join('Gemfile') }

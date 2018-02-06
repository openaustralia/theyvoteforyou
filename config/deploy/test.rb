set :branch, :test
set :deploy_to, "/srv/www/test.theyvoteforyou.org.au"

role :app, %w{deploy@kedumba.openaustraliafoundation.org.au}
role :web, %w{deploy@kedumba.openaustraliafoundation.org.au}
role :db,  %w{deploy@kedumba.openaustraliafoundation.org.au}

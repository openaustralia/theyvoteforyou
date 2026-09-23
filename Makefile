
init-submodules:
	git submodule update --init --recursive

install-ruby:
	rbenv install < .ruby-version

deploy-production:
	bundle exec cap production deploy
deploy-staging:
	bundle exec cap staging deploy

dev-services-up:
	COMPOSE_PROJECT_NAME=theyvoteforyou-dev docker compose -f docker-stack/dev/docker-compose.yml up --build -d mysql elasticsearch dejavu mailpit
# Full dev stack, including the app itself - an alternative to `bundle exec rails s` on the host.
dev-up:
	COMPOSE_PROJECT_NAME=theyvoteforyou-dev RUBY_VERSION=$$(cat .ruby-version) docker compose -f docker-stack/dev/docker-compose.yml up --build -d
test-services-up:
	COMPOSE_PROJECT_NAME=theyvoteforyou-test docker compose -f docker-stack/test/docker-compose.yml up --build -d

dev-load-data:
	bundle exec rake application:load:members
	bundle exec rake "application:load:divisions[$$(date -d '100 days ago' +%F),$$(date +%F)]"

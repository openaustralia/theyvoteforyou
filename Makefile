
init-submodules:
	git submodule update --init --recursive

install-ruby:
	rbenv install < .ruby-version

deploy-production:
	bundle exec cap production deploy
deploy-staging:
	bundle exec cap staging deploy

dev-services-up:
	COMPOSE_PROJECT_NAME=theyvoteforyou-dev docker compose -f docker-stack/dev/docker-compose.yml up --build -d
test-services-up:
	COMPOSE_PROJECT_NAME=theyvoteforyou-test docker compose -f docker-stack/test/docker-compose.yml up --build -d

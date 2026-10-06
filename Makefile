install-ruby:
	rbenv install < .ruby-version
dependencies:
	bundle install

# Deploys reach servers over SSM using the `oaf` profile (see config/deploy.rb), so make sure
# there's a live login first, starting `aws login` if there isn't.
aws-check:
	@command -v aws >/dev/null 2>&1 || { echo "ERROR: aws CLI not found." >&2; exit 1; }
	@aws sts get-caller-identity --profile oaf >/dev/null 2>&1 \
	  || { echo "Not logged in to AWS (profile oaf), starting login..."; aws login --profile oaf; }
	@aws sts get-caller-identity --profile oaf >/dev/null 2>&1 \
	  || { echo "ERROR: still not logged in to AWS (profile oaf)." >&2; exit 1; }
	@echo "OK: logged in to AWS (profile oaf)"

deploy-production: aws-check
	bundle exec cap production deploy

deploy-staging: aws-check dependencies
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

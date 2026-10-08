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

# The new theyvoteforyou2026 server (Ubuntu 26.04, rbenv), until it takes over from the current one (#1702).
# DEPLOY_APPLICATION picks the server by its EC2 Application tag; see the Capfile. Staging is the safe place to
# try it: it uses the staging database. Production uses the same database as the current server, so deploying
# there runs migrations against live data. Both deploy the branch named in the stage's config/deploy file, and
# STAGING_BRANCH=<branch> overrides that for staging, which is needed while Procfile.production.rbenv is not on main.
deploy-staging-2026: aws-check dependencies
	DEPLOY_APPLICATION=theyvoteforyou2026 bundle exec cap staging deploy

deploy-production-2026: aws-check
	DEPLOY_APPLICATION=theyvoteforyou2026 bundle exec cap production deploy

dev-services-up:
	COMPOSE_PROJECT_NAME=theyvoteforyou-dev docker compose -f docker-stack/dev/docker-compose.yml up --build -d mysql elasticsearch dejavu mailpit
# Full dev stack, including the app itself - an alternative to `bundle exec rails s` on the host.
dev-up:
	COMPOSE_PROJECT_NAME=theyvoteforyou-dev RUBY_VERSION=$$(cat .ruby-version) docker compose -f docker-stack/dev/docker-compose.yml up --build -d
test-services-up:
	COMPOSE_PROJECT_NAME=theyvoteforyou-test docker compose -f docker-stack/test/docker-compose.yml up --build -d

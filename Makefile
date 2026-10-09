.PHONY: help install-ruby dependencies aws-check deploy-production deploy-staging dev-services-up dev-up test-services-up

help: ## Show this help (the default target)
	@grep -E '^[a-z][a-zA-Z_-]*:.*## ' $(MAKEFILE_LIST) | \
	  awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

install-ruby: ## Install the Ruby version in .ruby-version using rbenv
	rbenv install < .ruby-version
dependencies: ## Install gems with bundle install
	bundle install

# Deploys reach servers over SSM using the `oaf` profile (see config/deploy.rb), so make sure
# there's a live login first, starting `aws login` if there isn't.
aws-check: ## Check for an AWS login (profile oaf), starting one if needed
	@command -v aws >/dev/null 2>&1 || { echo "ERROR: aws CLI not found." >&2; exit 1; }
	@aws sts get-caller-identity --profile oaf >/dev/null 2>&1 \
	  || { echo "Not logged in to AWS (profile oaf), starting login..."; aws login --profile oaf; }
	@aws sts get-caller-identity --profile oaf >/dev/null 2>&1 \
	  || { echo "ERROR: still not logged in to AWS (profile oaf)." >&2; exit 1; }
	@echo "OK: logged in to AWS (profile oaf)"

deploy-production: aws-check ## Deploy to production with Capistrano
	bundle exec cap production deploy

deploy-staging: aws-check dependencies ## Deploy to staging with Capistrano
	bundle exec cap staging deploy

dev-services-up: ## Start MySQL, Elasticsearch, dejavu and mailpit in Docker for development
	COMPOSE_PROJECT_NAME=theyvoteforyou-dev docker compose -f docker-stack/dev/docker-compose.yml up --build -d mysql elasticsearch dejavu mailpit
# Full dev stack, including the app itself - an alternative to `bundle exec rails s` on the host.
dev-up: ## Start the dev services plus the app itself, all in Docker
	COMPOSE_PROJECT_NAME=theyvoteforyou-dev RUBY_VERSION=$$(cat .ruby-version) docker compose -f docker-stack/dev/docker-compose.yml up --build -d
test-services-up: ## Start the services for the test environment in Docker
	COMPOSE_PROJECT_NAME=theyvoteforyou-test docker compose -f docker-stack/test/docker-compose.yml up --build -d

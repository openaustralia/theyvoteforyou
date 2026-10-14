.PHONY: help install-ruby dependencies aws-check deploy-production deploy-staging up services-up down clean clobber status logs shell

help: ## Show this help (the default target)
	@grep -hE '^[a-zA-Z0-9_.-]+:.*## ' $(MAKEFILE_LIST) | \
	  awk 'BEGIN {FS = ":.*## "}; {printf "  %-18s %s\n", $$1, $$2}'

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

# The stack is defined in .devcontainer/compose.yaml (see "Development environment" in AGENTS.md).
# --wait returns once every service passes its healthcheck, so the next command can use them straight away.
COMPOSE := RUBY_VERSION=$$(cat .ruby-version) docker compose

up: ## Start everything, including the app at http://localhost:3000, once it's ready
	$(COMPOSE) up --build --wait -d
services-up: ## Start MySQL, Elasticsearch, dejavu and mailpit only, for running the app on the host
	$(COMPOSE) up --build --wait -d mysql elasticsearch dejavu mailpit
down: ## Stop and remove the containers, keeping the databases
	$(COMPOSE) down --remove-orphans
# Everything this checkout built, so the next `make up` rebuilds from scratch. The databases are kept.
# VS Code's dev container builds its own images on top of compose's. Only this project's containers say which
# they are, so they're noted before `down` removes them.
clean: ## Remove containers, built images (VS Code's too), installed gems, logs, tmp and coverage, keeping the databases
	p=$$($(COMPOSE) config | sed -n 's/^name: //p'); \
	vsc=$$(docker ps -a --filter "label=com.docker.compose.project=$$p" --format '{{.Image}}' | grep '^vsc-' | sort -u); \
	$(COMPOSE) down --remove-orphans --rmi local && \
	docker volume rm --force "$${p}_bundle_cache" && \
	{ [ -z "$$vsc" ] || docker rmi --force $$vsc; }
	git clean -fdX -- log tmp coverage # gitignored files only, so tracked placeholders stay
# Reaches past this checkout, for after switching branches or changing dependencies. Other projects lose only
# download and build time, as volumes (where their databases live) are never pruned.
clobber: clean ## Also remove the databases, then all stopped containers, unused images and build cache machine-wide
	$(COMPOSE) down --volumes
	@echo "Pruning stopped containers, unused images and build cache from ALL projects (volumes are kept)"
	docker system prune --all --force
status: ## Show each container's health and the host ports it's published on
	@$(COMPOSE) ps -a --format 'table {{.Service}}\t{{.Status}}\t{{.Ports}}'
logs: ## Follow the logs of every container (or SERVICE=app for one)
	$(COMPOSE) logs -f $(SERVICE)
shell: ## Open a shell in the app container, or in a fresh one if it has stopped (e.g. after a failed start)
	@if [ -n "$$(docker compose ps -q --status running app)" ]; then docker compose exec app bash; else docker compose run --rm app bash; fi

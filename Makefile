.PHONY: help setup aws-check deploy-production deploy-staging up services-up down clean clobber status logs shell test lint console seed

help: ## Show this help (the default target)
	@grep -hE '^[a-zA-Z0-9_.-]+:.*## ' $(MAKEFILE_LIST) | \
	  awk 'BEGIN {FS = ":.*## "}; {printf "  %-18s %s\n", $$1, $$2}'

# For running Rails on the host. mise is preferred, rbenv works too; both read .ruby-version (mise via mise.toml).
# bin/setup can't install Ruby itself, as it needs Ruby to run.
setup: services-up ## Install Ruby (with mise or rbenv), gems and config, and prepare the database, to run Rails on the host
	@if command -v mise >/dev/null; then mise trust && mise install && mise exec -- bin/setup --skip-server; \
	elif command -v rbenv >/dev/null; then rbenv install --skip-existing && rbenv exec ruby bin/setup --skip-server; \
	else echo "Install mise (https://mise.jdx.dev) or rbenv first" >&2; exit 1; fi

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

deploy-staging: aws-check ## Deploy to staging with Capistrano
	bundle install
	bundle exec cap staging deploy

# The stack is defined in .devcontainer/compose.yaml (see "Development environment" in AGENTS.md).
# --wait returns once every service passes its healthcheck, so the next command can use them straight away.
COMPOSE := docker compose
# Runs a command in the app container, or in a fresh one if it has stopped
in_app = if [ -n "$$(docker compose ps -q --status running app)" ]; then docker compose exec app $(1); else $(COMPOSE) run --rm app $(1); fi

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
status: ## Show each container's health, the host ports it's published on, and where to browse
	@$(COMPOSE) ps -a --format 'table {{.Service}}\t{{.Status}}\t{{.Ports}}'
	@echo; port() { $(COMPOSE) port $$1 $$2 2>/dev/null | sed 's/.*://'; }; \
	p=$$(port app 3000); [ -z "$$p" ] || echo "Web:     http://theyvoteforyou.localhost:$$p/ (user: brenda@oaf.org.au, password: foofoofoo, and more in db/seeds.rb)"; \
	p=$$(port mailpit 8025); [ -z "$$p" ] || echo "Mailpit: http://mailpit.localhost:$$p/"; \
	p=$$(port dejavu 1358); [ -z "$$p" ] || echo "Dejavu:  http://dejavu.localhost:$$p/ (connect it to http://localhost:$$(port elasticsearch 9200))"
logs: ## Follow the logs of every container (or SERVICE=app for one)
	$(COMPOSE) logs -f $(SERVICE)
shell: ## Open a shell in the app container, or in a fresh one if it has stopped (e.g. after a failed start)
	@$(call in_app,bash)
# The same checks as CI, in the app container; see "Tests and linting" in AGENTS.md
test: ## Run the specs as CI does, after resetting the test database (ARGS=spec/models/x_spec.rb:42 to narrow)
	@$(call in_app,bash -c 'bin/rails db:test:prepare && RAILS_ENV=test bin/rspec $(ARGS)')
lint: ## Run RuboCop as CI does (ARGS=<paths> to narrow)
	@$(call in_app,bin/rubocop --parallel $(ARGS))
console: ## Open a Rails console in the app container
	@$(call in_app,bin/rails console)
# Real data from data.openaustralia.org.au, for a site that looks like production. About 4 minutes on a fast connection,
# mostly loading members, as every photo is checked. Skips people distances (the "friends" pages), which are slower.
FROM ?= 2021-07-01
TO ?= 2021-10-31
SEED_DIVISIONS := application:load:divisions[$(FROM),$(TO)]
seed: ## (SLOW) Load real members and divisions from FROM to TO, then rebuild caches and search, in the app container
	@$(call in_app,bin/rake application:load:members "$(SEED_DIVISIONS)" application:cache:all_except_people_distances searchkick:reindex:all)
	@echo 'Done. For links to the MPs who vote most like each person (the "friends" pages), also run (SLOW):'
	@echo "  make shell, then: bin/rake application:cache:people_distances"

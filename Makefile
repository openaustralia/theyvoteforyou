.PHONY: help setup deploy-production deploy-staging dev-up dev-hybrid dev-down dev-exec dev-console dev-dbconsole dev-server dev-rake dev-clobber dev-status

SHELL := /bin/bash

help:
	@echo "Available targets"
	@echo "  help                 Output this help text (default target)"
	@echo ""
	@echo "  deploy-production    Deploy to production via Capistrano"
	@echo "  deploy-staging       Deploy to staging via Capistrano"
	@echo ""
	@echo "  dev-up               Start the dev container and associated services, refreshing build if needed (required for the following targets)"
	@echo "  dev-hybrid           Start mysql/elasticsearch/mailpit only, no rails-app, for running Ruby on the host"
	@echo "  dev-status           Show container status, resource usage, and clickable service URLs"
	@echo "  dev-console          Run bin/rails console inside the running dev container"
	@echo "  dev-dbconsole        Run bin/rails dbconsole -p inside the running dev container"
	@echo "  dev-exec             Run COMMAND inside the running dev container (default: bash)"
	@echo "  dev-rake             Run bin/rake ARGS inside the running dev container (default: spec)"
	@echo "  dev-server           Run rails web server inside the running dev container"
	@echo "  dev-down             Stop the dev container"
	@echo ""
	@echo "  dev-clobber          Remove dev container images, volumes and orphans - full reset"
	@echo "  setup                Install devcontainer and docker on this host"
	@echo ""
	@echo "Extra vars:"
	@echo "  COMMAND            Command for dev-exec to run, e.g. COMMAND=\"bin/rails routes\" (default: bash)"
	@echo "  ARGS               Args for dev-rake, e.g. ARGS=\"db:test:prepare\""


# Installs Docker and devcontainer - see that file for details.
setup:
	bin/setup-host

deploy-production:
	bundle exec cap production deploy

deploy-staging:
	bundle exec cap staging deploy

DEVCONTAINER_STAMP := .make/dev-down.stamp
DEVCONTAINER_SOURCES := .devcontainer/compose.yaml .devcontainer/devcontainer.json .devcontainer/Dockerfile
SETUP_STAMP := .make/setup.stamp

.make:
	mkdir -p .make

LOCKFILE := .devcontainer/devcontainer-lock.json

# Keeps the committed lockfile in sync with devcontainer.json (see finding 11
# on #1656). `devcontainer upgrade` is a dedicated subcommand present in every
# CLI version checked so far (identical output confirmed on both 0.72.0 and
# 0.83.3), so this works regardless of whether a given install auto-generates
# a lockfile from `up`/`build` by default.
$(LOCKFILE): .devcontainer/devcontainer.json
	devcontainer upgrade --workspace-folder .

dev-up: $(DEVCONTAINER_STAMP) $(LOCKFILE)
	devcontainer up --workspace-folder .

# Trigger a dev-down if the container is stale so the next dev-up will rebuild
$(DEVCONTAINER_STAMP): $(DEVCONTAINER_SOURCES) | .make
	echo Stop the devcontainer so it will be rebuilt with changed sources ...
	$(MAKE) dev-down

dev-down: | .make
	docker compose -f .devcontainer/compose.yaml down
	touch $(DEVCONTAINER_STAMP)

# Just the supporting services, no rails-app, for the hybrid workflow (Ruby on the host, see
# README's "Using just the other services") and for measuring an IDE's own memory use without
# a devcontainer backend process competing for the same container's mem_limit.
dev-hybrid:
	docker compose -f .devcontainer/compose.yaml up -d mysql elasticsearch mailpit

dev-status:
	@docker compose -f .devcontainer/compose.yaml ps
	@echo ""
	@ids=$$(docker compose -f .devcontainer/compose.yaml ps -q); \
	if [ -n "$$ids" ]; then \
		docker stats --no-stream $$ids; \
		echo ""; \
		echo "  App:           http://localhost:3088  http://localhost:3088/rails/info/properties  http://localhost:3088/rails/info/routes"; \
		echo "                                        http://localhost:3088/rails/mailers  http://localhost:3088/rails/health"; \
		echo "  Elasticsearch: http://localhost:9288  http://localhost:9288/_cluster/health  http://localhost:9288/_cat/indices?v"; \
		echo "  Mailpit:       http://localhost:8088"; \
		echo "  MySQL:         mysql --host=127.0.0.1 --port=3388 --user=root --password=password"; \
	else \
		echo "(no containers running)"; \
	fi

# Defaults to bash - e.g. make dev-exec COMMAND="bin/rails routes"
COMMAND ?= bash

dev-exec:
	devcontainer exec --workspace-folder . $(COMMAND)

# Gems (and the rest of bin/setup) live inside the container, not in
# anything DEVCONTAINER_STAMP can see, so this is tracked separately.
# Depends on Gemfile/Gemfile.lock/bin/setup/config/database.yml.example -
# editing any of them forces a recheck - and is cleared by dev-clobber's
# `rm -rf .make` (a fresh bundler-cache volume wipes gems without touching
# any of those files). If bin/setup fails - e.g. a freshly (re)created
# volume defaults /bundle to root ownership - fix that and retry once
# before giving up.
$(SETUP_STAMP): Gemfile Gemfile.lock bin/setup config/database.yml.example | .make
	devcontainer exec --workspace-folder . bin/setup --skip-server
	touch $(SETUP_STAMP)

dev-console: $(SETUP_STAMP)
	devcontainer exec --workspace-folder . bin/rails console

dev-dbconsole: $(SETUP_STAMP)
	devcontainer exec --workspace-folder . bin/rails dbconsole -p

dev-server: $(SETUP_STAMP)
	devcontainer exec --workspace-folder . bin/dev -b 0.0.0.0

# e.g. make dev-rake ARGS="db:test:prepare"
ARGS ?= spec

dev-rake: $(SETUP_STAMP)
	devcontainer exec --workspace-folder . bin/rake $(ARGS)

dev-clobber:
	docker compose -f .devcontainer/compose.yaml down --rmi all --volumes --remove-orphans
	rm -rf .make


.PHONY: help setup deploy-production deploy-staging dev-up dev-exec dev-console dev-dbconsole dev-rake dev-clobber

SHELL := /bin/bash

help:
	@echo "Available targets"
	@echo "  help                 Output this help text (default target)"
	@echo "  deploy-production    Deploy to production via Capistrano"
	@echo "  deploy-staging       Deploy to staging via Capistrano"
	@echo "  setup                Install devcontainer and docker on this host (Ubuntu or macOS) via script/setup-host"
	@echo "  dev-up               Start the dev container and associated services"
	@echo "  dev-down             Stop the dev container"
	@echo "  dev-exec             Run COMMAND inside the running dev container (default: bash)"
	@echo "  dev-console          Open bin/rails console inside the running dev container"
	@echo "  dev-dbconsole        Open bin/rails dbconsole inside the running dev container"
	@echo "  dev-rake             Run bin/rake ARGS inside the running dev container"
	@echo "  dev-clobber          Remove dev container images, volumes and orphans - full reset"
	@echo ""
	@echo "Extra vars:"
	@echo "  COMMAND            Command for dev-exec to run, e.g. COMMAND=\"bin/rails routes\" (default: bash)"
	@echo "  ARGS               Args for dev-rake, e.g. ARGS=\"db:test:prepare\""


# Installs Docker and devcontainer (Ubuntu or macOS) - see that file for details.
setup:
	bin/setup-host

deploy-production:
	bundle exec cap production deploy

deploy-staging:
	bundle exec cap staging deploy

dev-up:
	devcontainer up --workspace-folder .

dev-down:
	docker compose -f .devcontainer/compose.yaml down

# Defaults to bash - e.g. make dev-exec COMMAND="bin/rails routes"
COMMAND ?= bash

dev-exec:
	devcontainer exec --workspace-folder . $(COMMAND)

dev-console:
	devcontainer exec --workspace-folder . bin/rails console

dev-dbconsole:
	devcontainer exec --workspace-folder . bin/rails dbconsole -p

# e.g. make dev-rake ARGS="db:test:prepare"
ARGS ?=

dev-rake:
	devcontainer exec --workspace-folder . bin/rake $(ARGS)

dev-clobber:
	docker compose -f .devcontainer/compose.yaml down --rmi all --volumes --remove-orphans


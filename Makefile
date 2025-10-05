
init-submodules:
	git submodule update --init --recursive

install-ruby:
	rbenv install < .ruby-version

deploy-production:
	bundle exec cap production deploy
deploy-staging:
	bundle exec cap staging deploy
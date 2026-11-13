# rbenv replaces RVM for server Ruby management

The Ubuntu 26.04 rebuild (issue #1702, ADR 0002) is the cheapest moment to move off RVM, which is the most
maintenance-heavy of the Ruby managers `openaustralia/infrastructure` supports. We chose rbenv over mise as the
conservative option; both are supported by the Ansible roles, but rbenv is the better-worn path for Capistrano
deployment.

## Consequences

- `config/deploy.rb` swaps `set :rvm_ruby_version` for the `capistrano-rbenv` equivalent, `Capfile` requires
  `capistrano/rbenv`, the `Gemfile` swaps `capistrano-rvm` for `capistrano-rbenv`, and the `Procfile.production`
  worker line drops its `rvm . do` wrapper.
- `group_vars/theyvoteforyou.yml` in `openaustralia/infrastructure` changes `ruby_manager: rvm` to `rbenv`.
- Ruby is still built from source on the server (Ubuntu 26.04 ships Ruby 3.3 in apt; `.ruby-version` pins 3.4.4).

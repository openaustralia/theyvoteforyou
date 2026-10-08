# frozen_string_literal: true

# Load DSL and Setup Up Stages
require "capistrano/setup"

# Includes default deployment tasks
require "capistrano/deploy"

# Includes tasks from other gems included in your Gemfile
#
# For documentation on these, see for example:
#
#   https://github.com/capistrano/rvm
#   https://github.com/capistrano/rbenv
#   https://github.com/capistrano/chruby
#   https://github.com/capistrano/bundler
#   https://github.com/capistrano/rails
#
# require 'capistrano/rvm'
# require 'capistrano/rbenv'
# require 'capistrano/chruby'
require "capistrano/rails"

# The server to deploy to is chosen by its EC2 Application tag, with the DEPLOY_APPLICATION environment variable.
# It defaults to the current server. The current server manages Ruby with RVM and the new theyvoteforyou2026 server
# with rbenv (ADR 0003), so each needs its own Capistrano plugin until the cutover (#1702). This is decided here
# because config/deploy.rb is only loaded after the Capfile.
DEPLOY_APPLICATION = ENV.fetch("DEPLOY_APPLICATION", "theyvoteforyou.org.au")
RUBY_MANAGER = {
  "theyvoteforyou.org.au" => :rvm,
  "theyvoteforyou2026" => :rbenv
}.fetch(DEPLOY_APPLICATION) do
  abort "DEPLOY_APPLICATION=#{DEPLOY_APPLICATION} is not one of: theyvoteforyou.org.au, theyvoteforyou2026"
end
require "capistrano/rvm" if RUBY_MANAGER == :rvm
require "capistrano/rbenv" if RUBY_MANAGER == :rbenv
require "capistrano/maintenance"
require "capistrano/scm/git"
require "capistrano/tagging3"
require "capistrano/aws"
require "net/ssh/proxy/command"
install_plugin Capistrano::SCM::Git

# Loads custom tasks from `lib/capistrano/tasks' if you have any defined.
Dir.glob("lib/capistrano/tasks/*.rake").each { |r| import r }

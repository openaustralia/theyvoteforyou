# frozen_string_literal: true

source "https://rubygems.org"

gem "rails", "~> 6.1.0"
gem "mysql2"

gem "sprockets"

# Use SCSS for stylesheets
gem "sass-rails"

# Use Uglifier as compressor for JavaScript assets
gem "uglifier", ">= 2.7.2"

# Use jquery as the JavaScript library
gem "jquery-rails"

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder"

gem "haml"
gem "htmlentities"

# TODO: Remove newrelic once we're happy that skylight is meeting our needs
gem "newrelic_rpm"
gem "skylight"

gem "devise"
gem "attribute-defaults"
gem "diffy"
gem "ranker"
gem "honeybadger"
gem "delayed_job_active_record"
gem "bootstrap-sass", "~> 3.3"
gem "autoprefixer-rails"
gem "mechanize" # Used to download debates
gem "nokogiri", ">= 1.6.7.2" # Explicitly included as it's used directly when testing division loader
gem "seed_dump"
gem "redcarpet"
gem "reverse_markdown"
# Lock paper_trail gem temporarily
# TODO: Upgrade paper_trail
gem "paper_trail", "12.2.0"
# TODO: This is using a fairly old version of the marked js lib. Update this gem
gem "marked-rails"
gem "simple_form"
gem "bootstrap-select-rails"
gem "foundation-icons-sass-rails"
# Only using font awesome for the bluesky logo. Definitely not ideal
gem "font-awesome-sass"
gem "meta-tags"
gem "numbers_and_words"

gem "searchkick"
# We're using elasticsearch 7.1 on the server. So, matching major version number for the gem
# TODO: Upgrade this when we upgrade the server
gem "elasticsearch", "~> 7"

# oj and typhoeus used for better performance with searchkick
# see https://github.com/ankane/searchkick#performance
gem "oj"
gem "typhoeus"

gem "foreman"

gem "rack-cors"

# Lock mini_racer version temporarily
# TODO: Upgrade mini_racer
gem "mini_racer", "0.6.2"

gem "invisible_captcha"

# For admin panel usable by admins
gem "administrate"

# Feature flag framework
gem "flipper"
gem "flipper-active_record"
gem "flipper-ui"

# Used for checking whether URLs are valid in rake task
gem "httparty"

# Used for taking screenshots of the social media cards in rake tas
gem "selenium-webdriver"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap"

# To show progress during some long running rake tasks
gem "ruby-progressbar"

# Authorization
gem "pundit"

# For proxying requests to plausible.io analytics
gem "rack-proxy"

# Locking base64 to workaround issue with deploying rails 6.1 to production:
# "You have already activated base64 0.1.0, but your Gemfile requires base64 0.2.0.
# Since base64 is a default gem, you can either remove your dependency on it or try
# updating to a newer version of bundler that supports base64 as a default gem. (Gem::LoadError)"
# See https://www.reddit.com/r/rails/comments/18105z2/ruby_on_rails_phusion_passenger_error/?rdt=51564
# TODO: Remove this workaround as soon as we can
gem "base64", "0.1.0"

# For some reason a dependency of mail 2.8.1 (net-imap) was causing the app not to start
# in production. So, locking to 2.7.1 to get things working again.
# TODO: Remove this workaround as soon as we can
gem "mail", "2.7.1"

group :test do
  gem "rspec-activemodel-mocks"
  gem "webmock"
  gem "vcr"
  gem "factory_bot_rails"
  gem "capybara"
  gem "email_spec"
  gem "simplecov", require: false
  gem "timecop"
  gem "rails-controller-testing"
end

group :development do
  # Required for html2haml
  gem "ruby_parser"

  gem "guard"
  gem "guard-rspec"
  gem "guard-livereload", require: false
  gem "rack-livereload"
  gem "guard-rubocop"

  gem "better_errors"
  gem "binding_of_caller"

  gem "rack-mini-profiler"

  # Used to show flamegraphs in development with rack-mini-profiler
  # Add ?pp=flamegraph to the end of the url in development
  gem "stackprof"

  gem "capistrano", require: false
  gem "capistrano-rails", require: false
  gem "capistrano-rvm"
  gem "capistrano-maintenance", require: false

  gem "mina"
  gem "mina-multistage", require: false
  gem "brakeman", require: false

  gem "rubocop", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false

  # Helps upgrade a whole bunch of gems at once
  gem "bummr"
end

group :test, :development do
  gem "rspec-rails"
  gem "fuubar"
end

group :production do
  # TODO: To upgrade to dalli 3 we need to make changes to the configuration
  # See https://github.com/petergoldstein/dalli/blob/main/3.0-Upgrade.md
  gem "dalli", "~>2"
end

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem "sdoc", require: false
end

# Use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]

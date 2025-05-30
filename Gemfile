# frozen_string_literal: true

source "https://rubygems.org"

gem "rails", "~> 8.0.0"
gem "mysql2"

gem "sprockets"

# Use SCSS for stylesheets
gem "sass-rails"

# Use jquery as the JavaScript library
gem "jquery-rails"

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder"

gem "haml"
gem "htmlentities"

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
gem "paper_trail"
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
# I think we need farady-typhoeus rather than typhoeus when using faraday 2
gem "faraday-typhoeus"

gem "foreman"

gem "rack-cors"

# TODO: Upgrade this when we can. I think we need to upgrade the ubuntu version on the server first.
gem "mini_racer", "~> 0.16.0"

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

# Needed for ruby 3.4.
# TODO: But will it be necessary once rails is upgraded?
gem "mutex_m"
gem "drb"

# For compressing javascript
gem "terser"

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
  gem "rubocop-rspec_rails", require: false
  gem "rubocop-capybara", require: false
  gem "rubocop-factory_bot", require: false

  # Helps upgrade a whole bunch of gems at once
  gem "bummr"
end

group :test, :development do
  gem "rspec-rails"
  gem "fuubar"
end

group :production do
  gem "dalli", "~>3"
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

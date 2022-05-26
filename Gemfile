# frozen_string_literal: true

source "https://rubygems.org"

gem "rails", "6.0.5"
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
# Necessary because we have a column called "valid" in the pw_divisions table.
# TODO Change the name of the column with a migration and remove this gem
gem "safe_attributes"
gem "newrelic_rpm"
gem "devise"
gem "attribute-defaults"
gem "diffy"
gem "ranker"
gem "honeybadger"
gem "delayed_job_active_record"
gem "bootstrap-sass", "~> 3.3"
gem "autoprefixer-rails"
gem "config"
gem "mechanize" # Used to download debates
gem "nokogiri", ">= 1.6.7.2" # Explicitly included as it's used directly when testing division loader
gem "seed_dump"
gem "redcarpet"
gem "reverse_markdown"
gem "paper_trail"
# TODO: This is using a fairly old version of the marked js lib. Update this gem
gem "marked-rails"
gem "simple_form"
gem "bootstrap-select-rails"
gem "foundation-icons-sass-rails"
gem "meta-tags"
gem "numbers_and_words"

gem "searchkick"

# oj and typhoeus used for better performance with searchkick
# see https://github.com/ankane/searchkick#performance
gem "oj"
gem "typhoeus"

gem "foreman"

gem "rack-cors"

gem "mini_racer"

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

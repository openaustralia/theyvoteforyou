# frozen_string_literal: true

source "https://rubygems.org"

gem "rails", "5.0.7.2"
gem "mysql2"

# TODO: Sprockets 4 is causing trouble for the time being
gem "sprockets", "< 4"

# Use SCSS for stylesheets
gem "sass-rails"

# Use Uglifier as compressor for JavaScript assets
gem "uglifier", ">= 2.7.2"

# Use CoffeeScript for .js.coffee assets and views
gem "coffee-rails"

# Use jquery as the JavaScript library
gem "jquery-rails"

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem "turbolinks"

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder", "~> 1.2"

gem "haml"
gem "htmlentities"
gem "marker", git: "https://github.com/openaustralia/marker", branch: "publicwhip", ref: "aa7ce85"
# Necessary because we have a column called "valid" in the pw_divisions table.
# TODO Change the name of the column with a migration and remove this gem
gem "safe_attributes"
gem "newrelic_rpm"
gem "devise"
# TODO: Re-add devise-async once upgraded Devise to 4.x and Rails to 5.x
# gem 'devise-async'
gem "attribute-defaults"
gem "diffy"
gem "ranker"
gem "honeybadger"
gem "delayed_job_active_record"
# TODO: Display of /people is broken when we upgrade to 3.3.5
gem "bootstrap-sass", "3.3.1.0"
gem "autoprefixer-rails"
gem "config"
gem "mechanize" # Used to download debates
gem "nokogiri", ">= 1.6.7.2" # Explicitly included as it's used directly when testing division loader
gem "seed_dump"
gem "redcarpet"
gem "reverse_markdown"
# TODO: Update to a not ancient version of paper_trail
gem "paper_trail", "~> 4"
# TODO: This is using a fairly old version of the marked js lib. Update this gem
gem "marked-rails"
gem "simple_form", "~> 3"
gem "bootstrap-select-rails"
gem "foundation-icons-sass-rails"
gem "meta-tags"
gem "numbers_and_words", "~> 0.10.0"
gem "searchkick", "<= 1.5.1"
gem "typhoeus"
gem "foreman"

gem "rack-cors"

gem "mini_racer"

gem "invisible_captcha"

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

  gem "mailcatcher"
  gem "rack-mini-profiler"

  # We've also locked the version if config/deploy.rb for some reason
  gem "capistrano", "3.7.2", require: false
  gem "capistrano-rails", "~> 1.1", require: false
  gem "capistrano-rvm"
  gem "capistrano-maintenance", "~> 1.0", require: false

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
  gem "dalli"
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

source 'https://rubygems.org'

gem 'rails', '4.1.4'
gem 'mysql2'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 4.0.0'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 1.2'

gem "haml"
gem "htmlentities"
gem 'marker', github: 'openaustralia/marker', branch: 'publicwhip', ref: 'aa7ce85'
# Necessary because we have a column called "valid" in the pw_divisions table.
# TODO Change the name of the column with a migration and remove this gem
gem 'safe_attributes'
gem 'newrelic_rpm'
gem 'devise'
gem 'attribute-defaults'
gem 'diffy'
gem 'ranker'
gem 'honeybadger'
gem 'delayed_job_active_record'
gem 'bootstrap-sass'
gem 'autoprefixer-rails'

group :test do
  # We can't use transactional fixtures as the php app and the rails app need to see
  # the same database. So, using database_cleaner instead
  gem "database_cleaner"
  gem 'mechanize' # Used in HTMLCompareHelper
  gem 'rspec-activemodel-mocks'
end

group :development do
  # Required for html2haml
  gem "ruby_parser"

  gem 'guard'
  gem 'guard-rspec'

  gem 'better_errors'
  gem 'binding_of_caller'

  gem 'mailcatcher'

  gem 'capistrano', '~> 3.0', require: false
  gem 'capistrano-rails',   '~> 1.1', require: false
  gem 'capistrano-bundler', '~> 1.1', require: false
  gem 'rvm1-capistrano3', require: false
end

group :test, :development do
  # We're not quite ready to move to rspec 3 just yet
  gem "rspec-rails", "< 3.0.0"
end

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

# Use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]

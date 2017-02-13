source 'https://rubygems.org'

gem 'rails', '~> 4.2.7'
gem 'mysql2'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 4.0.0'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 2.7.2'

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
gem 'marker', git: 'https://github.com/openaustralia/marker', branch: 'publicwhip', ref: 'aa7ce85'
# Necessary because we have a column called "valid" in the pw_divisions table.
# TODO Change the name of the column with a migration and remove this gem
gem 'safe_attributes'
gem 'newrelic_rpm'
gem 'devise', '~> 3.5'
gem 'devise-async'
gem 'attribute-defaults'
gem 'diffy'
gem 'ranker'
gem 'honeybadger'
gem 'delayed_job_active_record', '~> 4.0.3'
gem 'bootstrap-sass', '~> 3.3.1'
gem 'autoprefixer-rails'
gem 'rails_config'
gem 'mechanize' # Used to download debates
gem 'nokogiri', '>= 1.6.7.2' # Explicitly included as it's used directly when testing division loader
gem 'seed_dump'
gem "redcarpet"
gem "reverse_markdown"
gem 'paper_trail'
# TODO This is using a fairly old version of the marked js lib. Update this gem
gem "marked-rails"
gem 'simple_form', '~> 3'
gem 'bootstrap-select-rails'
gem 'foundation-icons-sass-rails'
gem 'meta-tags'
gem 'numbers_and_words', '~> 0.10.0'
gem 'searchkick'
gem 'typhoeus'
gem 'foreman'

group :test do
  # We can't use transactional fixtures as the php app and the rails app need to see
  # the same database. So, using database_cleaner instead
  gem "database_cleaner"
  gem 'rspec-activemodel-mocks'
  gem 'webmock'
  gem 'vcr'
  gem 'factory_girl_rails'
  gem 'capybara'
  gem 'email_spec'
  gem "codeclimate-test-reporter", group: :test, require: nil
  gem "timecop"
end

group :development do
  # Required for html2haml
  gem "ruby_parser"

  gem 'guard'
  gem 'guard-rspec'
  gem 'guard-livereload', require: false
  gem 'rack-livereload'

  gem 'better_errors'
  gem 'binding_of_caller'

  gem 'mailcatcher'
  gem 'rack-mini-profiler'

  gem 'capistrano', '~> 3.0', require: false
  gem 'capistrano-rails',   '~> 1.1', require: false
  gem 'capistrano-bundler', '~> 1.1', require: false
  gem 'rvm1-capistrano3', require: false
  gem 'capistrano-maintenance', '~> 1.0', require: false

  gem 'mina'
  gem 'mina-multistage', require: false
end

group :test, :development do
  gem 'rspec-rails', '~> 3.5'
  gem 'fuubar'
end

group :production do
  gem 'dalli'
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

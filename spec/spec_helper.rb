# frozen_string_literal: true

require "simplecov"
SimpleCov.start "rails" do
  # Don't include admin panel stuff in coverage
  add_filter "/app/controllers/admin/"
  add_filter "/app/dashboards/"
end

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../config/environment", __dir__)
require "rspec/rails"
require "capybara/rspec"
require "email_spec"
require "html_compare_helper"
require "fixtures_with_factories"
require "webmock/rspec"

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Rails.root.glob("spec/support/**/*.rb").each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.check_all_pending! if defined?(ActiveRecord::Migration)

VCR.configure do |c|
  c.cassette_library_dir = "spec/vcr_cassettes"
  c.hook_into :webmock
  # c.default_cassette_options = { record: :new_episodes }
  # So that codeclimate-test-reporter can do its work
  c.ignore_hosts "codeclimate.com"
end

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [Rails.root.join("spec/fixtures")]

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  # Disabled so emails in acceptance tests work
  config.use_transactional_fixtures = true

  config.before(:suite) do
    Delayed::Worker.delay_jobs = false
    Searchkick.disable_callbacks

    # See https://github.com/thoughtbot/factory_bot/blob/master/GETTING_STARTED.md#linting-factories
    ActiveRecord::Base.transaction do
      FactoryBot.lint
      raise ActiveRecord::Rollback
    end
  end

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  config.include FactoryBot::Syntax::Methods

  config.include EmailSpec::Helpers
  config.include EmailSpec::Matchers

  config.include Devise::Test::ControllerHelpers, type: :controller
end

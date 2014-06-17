# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'html_compare_helper'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.check_pending! if defined?(ActiveRecord::Migration)

def get_salt(rails_env)
  # If you know a nicer way of pulling the secrets from another env out, please
  # let me know.
  raw_secrets = File.read("#{::Rails.root.to_s}/config/secrets.yml")
  erb_secrets = ERB.new(raw_secrets).result
  secrets = YAML.load(erb_secrets)[rails_env]
  secrets["php_id_hash_salt"]
end

# Set the PHP app's configration to match a ruby environment
def set_php_config(rails_env)
  db = ActiveRecord::Base.configurations[rails_env]["database"]
  db_user = ActiveRecord::Base.configurations[rails_env]["username"]
  db_pass = ActiveRecord::Base.configurations[rails_env]["password"]
  salt = get_salt(rails_env)

  text = File.read("../website/config.php")
  File.open("../website/config.php", "w") do |f|
    text.gsub!(/\$pw_database = (.*);/, "$pw_database = \"#{db}\";")
    text.gsub!(/\$pw_user = (.*);/, "$pw_user = \"#{db_user}\";")
    text.gsub!(/\$pw_password = (.*);/, "$pw_password = \"#{db_pass}\";")
    text.gsub!(/\$hidden_hash_var=(.*);/, "$hidden_hash_var='#{salt}';")
    f.puts text
  end
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
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.

  # We can't use transactional fixtures as the php app and the rails app need to see
  # the same database. So, using database_cleaner instead
  config.use_transactional_fixtures = false

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)

    FileUtils.rm_f("old.html")
    FileUtils.rm_f("new.html")

    # Point the php app to the test database
    set_php_config "test"
 end

  config.after(:suite) do
    # Point the php app to the development database
    set_php_config "development"
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
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

end

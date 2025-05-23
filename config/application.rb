require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# This is for proxying requests to this server to plausible.io for analytics.
# See https://plausible.io/docs/proxy/introduction
# For some reason didn't work putting this in config/initializers/proxy.rb
# TODO: Fix this
class PlausibleProxy < Rack::Proxy
  def perform_request(env)
    request = Rack::Request.new(env)

    # use rack proxy for anything hitting plausible analytics endpoints
    if request.path =~ %r{^/js/script\.} || request.path =~ %r{^/api/event}
        # most backends required host set properly, but rack-proxy doesn't set this for you automatically
        # even when a backend host is passed in via the options
        env["HTTP_HOST"] = "plausible.io"

        # don't send your sites cookies to target service, unless it is a trusted internal service that can parse all your cookies
        env['HTTP_COOKIE'] = ''

        env['content-length'] = nil

        super(env)
    else
      @app.call(env)
    end
  end
end

module Publicwhip
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    config.active_support.cache_format_version = 7.1
    config.add_autoload_paths_to_load_path = false

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.

    config.exceptions_app = routes

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = "Sydney"

    config.middleware.use PlausibleProxy

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.autoload_paths += %W[#{config.root}/lib]

    config.to_prepare do
      Devise::Mailer.layout "email" # email.haml or email.erb
    end

    # Because we're using the yaml serialising for paper trail (the old but not now recommended way) with rails 7.1
    # we need to tell rails what classes we can "safely" serialise.
    # See https://github.com/paper-trail-gem/paper_trail/blob/master/doc/pt_13_yaml_safe_load.md#to-continue-using-the-yaml-serializer
    # TODO: Switch over to json serialisation for paper trail to avoid this whole issue
    config.active_record.yaml_column_permitted_classes = [
      ::ActiveRecord::Type::Time::Value,
      ::ActiveSupport::TimeWithZone,
      ::ActiveSupport::TimeZone,
      ::BigDecimal,
      ::Date,
      ::Symbol,
      ::Time
    ]

    #
    # Application configuration below here
    #

    # URL where Public Whip XML data files can be found
    config.xml_data_base_url = "http://data.openaustralia.org.au/"
    # Or if you want to load from your local filesystem instead then you might do something like
    #config.xml_data_base_url = "file:///Users/matthew/git/openaustralia/openaustralia-parser/pwdata/"

    # Name of project to display thoughout the application
    config.project_name = "They Vote For You"

    config.contact_email = "contact@theyvoteforyou.org.au"

    config.facebook_admins = nil
  end
end

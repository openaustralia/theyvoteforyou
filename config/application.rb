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
    config.load_defaults 6.1

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.

    config.exceptions_app = routes

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = Settings.time_zone

    config.middleware.use PlausibleProxy

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.autoload_paths += %W[#{config.root}/lib]

    config.to_prepare do
      Devise::Mailer.layout "email" # email.haml or email.erb
    end
  end
end

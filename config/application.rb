require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Publicwhip
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    config.exceptions_app = routes

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = Settings.time_zone

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.autoload_paths += %W[#{config.root}/lib]

    config.to_prepare do
      Devise::Mailer.layout "email" # email.haml or email.erb
    end

    # Really we should be able to set this in config/initializers/new_framework_defaults_6_0.rb but
    # it doesn't work.
    # TODO: Remove this once we switch to "config.load_defaults 6.0" above
    config.action_mailer.delivery_job = "ActionMailer::MailDeliveryJob"
  end
end

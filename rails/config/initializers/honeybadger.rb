Honeybadger.configure do |config|
  config.api_key = Rails.application.secrets.honeybadger_api_key
end

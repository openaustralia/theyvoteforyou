InvisibleCaptcha.setup do |config|
  # Set this to true for development so a human can see
  # the honeypot field
  config.visual_honeypots = false
  config.timestamp_enabled = !Rails.env.test?
end

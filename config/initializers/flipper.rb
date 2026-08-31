# frozen_string_literal: true

Flipper::UI.configure do |config|
  config.descriptions_source = lambda do |_keys|
    # This should be a complete list of all features being currently used in the codebase.
    # Keys are strings, because that is what Flipper looks features up by.
    {
      "altcha" => "Show the ALTCHA spam check on the sign up, log in, password reset and resend " \
                  "confirmation forms, and log whether it passes. On its own this blocks nothing. " \
                  "Use the on/off gate only, never a percentage gate: the form is rendered by one " \
                  "request and submitted by another, so a percentage can hand somebody a form with " \
                  "no widget and then refuse their submission.",
      "altcha_enforce" => "Reject sign up, log in, password reset and resend confirmation " \
                          "submissions whose ALTCHA check is missing or fails. Does nothing unless " \
                          "'altcha' is on too, so switching 'altcha' off is a full rollback on its " \
                          "own. While this is on, people with JavaScript turned off cannot use " \
                          "these four forms. On/off gate only, as above."
    }
  end

  # Defaults to false. Set to true to show feature descriptions on the list
  # page as well as the view page.
  config.show_feature_description_in_list = true
end

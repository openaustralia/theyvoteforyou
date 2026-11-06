# frozen_string_literal: true

Flipper::UI.configure do |config|
  config.descriptions_source = lambda do |_keys|
    # This should be a complete list of all features being currently used in the codebase
    {
      ai_disclosure: "Disclosure of AI use in division summaries (issue #1854). Per user: the \"Drafted with AI " \
                     "assistance\" fields on the summary form, the note on the division page and the /help/ai page. " \
                     "Everyone at once: the ai_assisted and ai_model API fields, the ai_assisted filter and their " \
                     "docs. Enabling it for particular users only means editors can record AI use that the API " \
                     "does not return yet."
    }
  end

  # Defaults to false. Set to true to show feature descriptions on the list
  # page as well as the view page.
  config.show_feature_description_in_list = true
end

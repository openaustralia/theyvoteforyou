# Use this setup block to configure all options available in SimpleForm.
SimpleForm.setup do |config|
  config.wrappers :vertical_form, tag: "div", class: "form-group", error_class: "has-error" do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label, class: "control-label"

    b.use :input, class: "form-control"
    b.use :error, wrap_with: { tag: "span", class: "help-block" }
    b.use :hint,  wrap_with: { tag: "p", class: "hint-block" }
  end

  config.wrappers :vertical_file_input, tag: "div", class: "form-group", error_class: "has-error" do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :readonly
    b.use :label, class: "control-label"

    b.use :input
    b.use :error, wrap_with: { tag: "span", class: "help-block" }
    b.use :hint,  wrap_with: { tag: "p", class: "help-block" }
  end

  config.wrappers :vertical_boolean, tag: "div", class: "form-group", error_class: "has-error" do |b|
    b.use :html5
    b.optional :readonly

    b.wrapper tag: "div", class: "checkbox" do |ba|
      ba.use :label_input
    end

    b.use :error, wrap_with: { tag: "span", class: "help-block" }
    b.use :hint,  wrap_with: { tag: "p", class: "help-block" }
  end

  config.wrappers :vertical_radio_and_checkboxes, tag: "div", class: "form-group", error_class: "has-error" do |b|
    b.use :html5
    b.optional :readonly
    b.use :label_input
    b.use :error, wrap_with: { tag: "span", class: "help-block" }
    b.use :hint,  wrap_with: { tag: "p", class: "help-block" }
  end

  config.wrappers :horizontal_form, tag: "div", class: "form-group", error_class: "has-error" do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label, class: "col-sm-3 control-label"

    b.wrapper tag: "div", class: "col-sm-9" do |ba|
      ba.use :input, class: "form-control"
      ba.use :error, wrap_with: { tag: "span", class: "help-block" }
      ba.use :hint,  wrap_with: { tag: "p", class: "help-block" }
    end
  end

  config.wrappers :horizontal_file_input, tag: "div", class: "form-group", error_class: "has-error" do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :readonly
    b.use :label, class: "col-sm-3 control-label"

    b.wrapper tag: "div", class: "col-sm-9" do |ba|
      ba.use :input
      ba.use :error, wrap_with: { tag: "span", class: "help-block" }
      ba.use :hint,  wrap_with: { tag: "p", class: "help-block" }
    end
  end

  config.wrappers :horizontal_boolean, tag: "div", class: "form-group", error_class: "has-error" do |b|
    b.use :html5
    b.optional :readonly

    b.wrapper tag: "div", class: "col-sm-offset-3 col-sm-9" do |wr|
      wr.wrapper tag: "div", class: "checkbox" do |ba|
        ba.use :label_input, class: "col-sm-9"
      end

      wr.use :error, wrap_with: { tag: "span", class: "help-block" }
      wr.use :hint,  wrap_with: { tag: "p", class: "help-block" }
    end
  end

  config.wrappers :horizontal_radio_and_checkboxes, tag: "div", class: "form-group", error_class: "has-error" do |b|
    b.use :html5
    b.optional :readonly

    b.use :label, class: "col-sm-3 control-label"

    b.wrapper tag: "div", class: "col-sm-9" do |ba|
      ba.use :input
      ba.use :error, wrap_with: { tag: "span", class: "help-block" }
      ba.use :hint,  wrap_with: { tag: "p", class: "help-block" }
    end
  end

  config.wrappers :inline_form, tag: "div", class: "form-group", error_class: "has-error" do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label, class: "sr-only"

    b.use :input, class: "form-control"
    b.use :error, wrap_with: { tag: "span", class: "help-block" }
    b.use :hint,  wrap_with: { tag: "p", class: "help-block" }
  end

  # Wrappers for forms and inputs using the Bootstrap toolkit.
  # Check the Bootstrap docs (http://getbootstrap.com)
  # to learn about the different styles for forms and inputs,
  # buttons and other elements.
  config.default_wrapper = :vertical_form

  # Define the way to render check boxes / radio buttons with labels.
  # Defaults to :nested for bootstrap config.
  #   inline: input + label
  #   nested: label > input
  config.boolean_style = :nested

  # Default class for buttons
  config.button_class = "btn btn-default"

  # Method used to tidy up errors. Specify any Rails Array method.
  # :first lists the first message for each field.
  # Use :to_sentence to list all errors for each field.
  # config.error_method = :first

  # Default tag used for error notification helper.
  config.error_notification_tag = :div

  # CSS class to add for error notification helper.
  config.error_notification_class = "alert alert-danger"

  # ID to add for error notification helper.
  # config.error_notification_id = nil

  # Series of attempts to detect a default label method for collection.
  # config.collection_label_methods = [ :to_label, :name, :title, :to_s ]

  # Series of attempts to detect a default value method for collection.
  # config.collection_value_methods = [ :id, :to_s ]

  # You can wrap a collection of radio/check boxes in a pre-defined tag, defaulting to none.
  # config.collection_wrapper_tag = nil

  # You can define the class to use on all collection wrappers. Defaulting to none.
  # config.collection_wrapper_class = nil

  # You can wrap each item in a collection of radio/check boxes with a tag,
  # defaulting to :span. Please note that when using :boolean_style = :nested,
  # SimpleForm will force this option to be a label.
  # config.item_wrapper_tag = :span

  # You can define a class to use in all item wrappers. Defaulting to none.
  # config.item_wrapper_class = nil

  # How the label text should be generated altogether with the required text.
  config.label_text = ->(label, _required, _explicit_label) { label }

  # You can define the class to use on all labels. Default is nil.
  # config.label_class = nil

  # You can define the class to use on all forms. Default is simple_form.
  # config.form_class = :simple_form

  # You can define which elements should obtain additional classes
  # config.generate_additional_classes_for = [:wrapper, :label, :input]

  # Whether attributes are required by default (or not). Default is true.
  # config.required_by_default = true

  # Tell browsers whether to use the native HTML5 validations (novalidate form option).
  # These validations are enabled in SimpleForm's internal config but disabled by default
  # in this configuration, which is recommended due to some quirks from different browsers.
  # To stop SimpleForm from generating the novalidate option, enabling the HTML5 validations,
  # change this configuration to true.
  config.browser_validations = false

  # Collection of methods to detect if a file type was given.
  # config.file_methods = [ :mounted_as, :file?, :public_filename ]

  # Custom mappings for input types. This should be a hash containing a regexp
  # to match as key, and the input type that will be used when the field name
  # matches the regexp as value.
  # config.input_mappings = { /count/ => :integer }

  # Custom wrappers for input types. This should be a hash containing an input
  # type as key and the wrapper that will be used for all inputs with specified type.
  # config.wrapper_mappings = { string: :prepend }

  # Namespaces where SimpleForm should look for custom input classes that
  # override default inputs.
  # config.custom_inputs_namespaces << "CustomInputs"

  # Default priority for time_zone inputs.
  # config.time_zone_priority = nil

  # Default priority for country inputs.
  # config.country_priority = nil

  # When false, do not use translations for labels.
  # config.translate_labels = true

  # Automatically discover new inputs in Rails' autoload path.
  # config.inputs_discovery = true

  # Cache SimpleForm inputs discovery
  # config.cache_discovery = !Rails.env.development?

  # Default class for inputs
  # config.input_class = nil

  # Define the default class of the input wrapper of the boolean input.
  config.boolean_label_class = nil

  # Defines if the default input wrapper class should be included in radio
  # collection wrappers.
  # config.include_default_input_wrapper_class = true

  # Defines which i18n scope will be used in Simple Form.
  # config.i18n_scope = 'simple_form'
end

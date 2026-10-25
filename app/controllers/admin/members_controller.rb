# frozen_string_literal: true

module Admin
  class MembersController < Admin::ApplicationController
    # Members come from the data loader, so this is for looking, not editing
    def valid_action?(name, resource = resource_class)
      %w[new edit destroy].exclude?(name.to_s) && super
    end
  end
end

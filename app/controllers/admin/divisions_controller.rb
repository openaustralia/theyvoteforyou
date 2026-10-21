# frozen_string_literal: true

module Admin
  class DivisionsController < Admin::ApplicationController
    # For the link to the division on the public site. Administrate's controllers don't load the
    # app's helpers.
    helper PathHelper

    # The list shows each division's summary status (SummaryStatusField), which reads
    # these two, so load them once rather than once per row.
    def scoped_resource
      super.includes(:wiki_motions, :ai_division_summaries)
    end
  end
end

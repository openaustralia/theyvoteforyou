# frozen_string_literal: true

module Admin
  # Where admins upload files for the background ingest queue (Ingest) and see how they went.
  class IngestsController < Admin::ApplicationController
    # For the links from the list of drafts to each division's edit form.
    helper PathHelper

    # The list and detail pages are Administrate's. New and create are our own upload form, and
    # an ingest is never edited or deleted from here.
    def valid_action?(name, resource = resource_class)
      %w[edit update destroy].exclude?(name.to_s) && super
    end

    def new
      @kind = kind_param
    end

    def create
      @kind = kind_param
      upload = params[:file]
      return redirect_to(new_admin_ingest_path(kind: @kind), alert: "Choose a zip file to upload") unless upload.respond_to?(:tempfile)
      return redirect_to(new_admin_ingest_path(kind: @kind), alert: "The file must be a .zip") unless upload.original_filename.to_s.downcase.end_with?(".zip")

      ingest = Ingest.queue!(kind: @kind, user: current_user, upload: upload)
      redirect_to admin_ingest_path(ingest), notice: "Uploaded. It is queued and will be read shortly."
    end

    # Removes every draft that arrived in this upload, for when a zip turns out to be bad. The
    # upload's own row stays, as a record that it happened.
    def delete_summaries
      deleted = requested_resource.ai_division_summaries.destroy_all.size
      redirect_to admin_ingest_path(requested_resource), notice: "Deleted #{deleted} #{'draft'.pluralize(deleted)} from this upload."
    end

    private

    def kind_param
      Ingest::KINDS.include?(params[:kind]) ? params[:kind] : "division-summary"
    end
  end
end

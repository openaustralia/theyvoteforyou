# frozen_string_literal: true

module Admin
  # Where admins upload files for the background ingest queue (Ingest) and see how they went.
  class IngestsController < Admin::ApplicationController
    # For the links from the list of drafts to each division's edit form.
    helper PathHelper

    def new
      @kind = kind_param
    end

    def create
      @kind = kind_param
      upload = params[:file]
      return refuse("Choose a zip file to upload") unless upload.respond_to?(:tempfile)
      return refuse("The file must be a .zip") unless upload.original_filename.to_s.downcase.end_with?(".zip")

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
      Ingest::KINDS.include?(params[:kind]) ? params[:kind] : Ingest::KINDS.first
    end

    def refuse(message)
      redirect_to new_admin_ingest_path(kind: @kind), alert: message
    end
  end
end

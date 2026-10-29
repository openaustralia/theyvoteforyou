# frozen_string_literal: true

module Admin
  # Where admins upload files for the background ingest queue (Ingest) and see how they went.
  class IngestsController < Admin::ApplicationController
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

    private

    def kind_param
      Ingest::KINDS.include?(params[:kind]) ? params[:kind] : Ingest::KINDS.first
    end

    def refuse(message)
      redirect_to new_admin_ingest_path(kind: @kind), alert: message
    end
  end
end

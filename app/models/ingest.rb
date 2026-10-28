# frozen_string_literal: true

# A file an admin has uploaded for us to process in the background, so a large file doesn't hold up
# the request. The file is kept on disk under Rails.configuration.x.ingest_root, one folder per
# row, and ProcessIngestJob does the reading. Nothing is published: an ingest only creates drafts
# for a human to review.
#
# `kind` says what the file holds. Only "division-summary" exists so far (DivisionSummaryIngest);
# the column is there so other kinds can be added later.
class Ingest < ApplicationRecord
  # `type` is a column name Rails reserves for single table inheritance, and we use it as a plain
  # string here. Ingests use `kind` for that reason.
  KINDS = %w[division-summary].freeze

  belongs_to :user, optional: true
  has_many :ai_division_summaries, dependent: :nullify

  enum :status, { queued: "queued", processing: "processing", done: "done", failed: "failed" }, default: :queued

  validates :kind, inclusion: { in: KINDS }

  # Saves the uploaded file, then queues the job that reads it. The file is written after the row
  # so its folder can be named by the row's id, and the job is queued last so it never runs
  # before the file is there.
  def self.queue!(kind:, user:, upload:)
    ingest = transaction do
      row = create!(kind: kind, user: user, original_filename: File.basename(upload.original_filename))
      row.store!(upload)
      row
    end
    ProcessIngestJob.perform_later(ingest)
    ingest
  end

  def store!(upload)
    folder = Rails.configuration.x.ingest_root.join(id.to_s)
    FileUtils.mkdir_p(folder, mode: 0o775)
    path = folder.join("upload.zip")
    FileUtils.cp(upload.tempfile.path, path)
    update!(file_path: path.to_s)
  end
end

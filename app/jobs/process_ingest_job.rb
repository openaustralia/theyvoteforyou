# frozen_string_literal: true

# Reads an uploaded Ingest in the background. Runs on Delayed Job through Active Job, like the
# other jobs here.
class ProcessIngestJob < ApplicationJob
  queue_as :default

  PROCESSORS = { "division-summary" => DivisionSummaryIngest }.freeze
  # The error column is TEXT (64 KB), which thousands of bad files would overflow.
  MAX_REPORTED_ERRORS = 50

  def perform(ingest)
    ingest.processing!
    result = PROCESSORS.fetch(ingest.kind).new(ingest).process
    ingest.update!(status: result.errors.empty? ? :done : :failed, records_saved: result.saved,
                   error: error_text(result.errors), processed_at: Time.current)
    ingest.discard_upload! if ingest.done?
  rescue StandardError => e
    Sentry.capture_exception(e)
    ingest.update!(status: :failed, error: "#{e.class}: #{e.message}", processed_at: Time.current)
  end

  private

  def error_text(errors)
    lines = errors.first(MAX_REPORTED_ERRORS)
    lines << "...and #{errors.size - MAX_REPORTED_ERRORS} more" if errors.size > MAX_REPORTED_ERRORS
    lines.join("\n").presence
  end
end

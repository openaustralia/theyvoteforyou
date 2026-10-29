# frozen_string_literal: true

# Reads an uploaded Ingest in the background. Runs on Delayed Job through Active Job, like the
# other jobs here.
class ProcessIngestJob < ApplicationJob
  queue_as :default

  PROCESSORS = { "division-summary" => DivisionSummaryIngest }.freeze

  def perform(ingest)
    ingest.processing!
    result = PROCESSORS.fetch(ingest.kind).new(ingest).process
    ingest.update!(status: result.errors.empty? ? :done : :failed, records_saved: result.saved,
                   error: result.errors.join("\n").presence, processed_at: Time.current)
  rescue StandardError => e
    Sentry.capture_exception(e)
    ingest.update!(status: :failed, error: "#{e.class}: #{e.message}", processed_at: Time.current)
  end
end

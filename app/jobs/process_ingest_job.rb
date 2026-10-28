# frozen_string_literal: true

# Reads an uploaded Ingest in the background. Runs on Delayed Job through Active Job, like the
# other jobs here.
class ProcessIngestJob < ApplicationJob
  queue_as :default

  PROCESSORS = { "division-summary" => DivisionSummaryIngest }.freeze

  def perform(ingest)
    ingest.processing!
    result = PROCESSORS.fetch(ingest.kind).new(ingest).process
    if result.errors.empty?
      ingest.update!(status: :done, records_saved: result.saved, error: nil, processed_at: Time.current)
    else
      ingest.update!(status: :failed, records_saved: 0, error: result.errors.join("\n"), processed_at: Time.current)
    end
  rescue StandardError => e
    ingest.update!(status: :failed, error: "#{e.class}: #{e.message}", processed_at: Time.current)
  end
end

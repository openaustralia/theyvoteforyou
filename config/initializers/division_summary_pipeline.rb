# frozen_string_literal: true

# The AI division summary pipeline keeps each stage's files in its own folder (context/,
# routing/, extraction/, validation/, compilation/) so the layout shows the five stages, but
# every class is still DivisionSummaryPipeline::Something. Collapsing tells Zeitwerk the folders
# are for people, not namespaces. See app/services/division_summary_pipeline/ARCHITECTURE.md.
Rails.autoloaders.main.collapse(Rails.root.join("app/services/division_summary_pipeline/*"))

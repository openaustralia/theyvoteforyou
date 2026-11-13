# frozen_string_literal: true

# Links a draft to the upload it arrived in (see Ingest), which also says which admin uploaded it.
# Null for drafts the pipeline made itself.
class AddIngestToAiDivisionSummaries < ActiveRecord::Migration[8.0]
  def change
    add_column :ai_division_summaries, :ingest_id, :integer
    add_index :ai_division_summaries, :ingest_id
  end
end

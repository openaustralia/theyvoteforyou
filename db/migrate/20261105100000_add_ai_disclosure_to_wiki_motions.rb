# frozen_string_literal: true

# Records whether an editor used AI to draft a summary (a WikiMotion), and which model.
# ai_assisted is deliberately nullable: existing rows stay null (unknown) rather than being backfilled to false.
class AddAiDisclosureToWikiMotions < ActiveRecord::Migration[8.0]
  def change
    add_column :wiki_motions, :ai_assisted, :boolean
    add_column :wiki_motions, :ai_model, :string
    add_index :wiki_motions, :ai_model
  end
end

# frozen_string_literal: true

# Keeps the prompt each AI division summary draft was made from, so a published summary can be
# checked months later, once Hansard or the pipeline code has changed and the prompt can no longer
# be rebuilt (KI-40).
#
# MEDIUMTEXT (up to 16 MB) rather than TEXT (64 KB): the sitting day prompt for Senate 18 August
# 2026 #16 was 104,305 bytes, and that division's draft description was already 50,610 bytes, so
# a longer guillotine draft would have failed to save.
class AddPromptsToAiDivisionSummaries < ActiveRecord::Migration[8.0]
  def up
    change_table :ai_division_summaries, bulk: true do |t|
      t.text :system_prompt, size: :medium
      t.text :user_prompt, size: :medium
      t.change :description, :text, size: :medium
    end
  end

  def down
    change_table :ai_division_summaries, bulk: true do |t|
      t.change :description, :text
      t.remove :user_prompt, :system_prompt
    end
  end
end

# frozen_string_literal: true

# A division's own name is TEXT because Hansard's headings can be long (the longest we hold is 298
# characters), and a draft's title is written in the same shape, so a 255 character VARCHAR cut
# off a real draft in an upload (see DivisionSummaryIngest).
class WidenAiDivisionSummaryTitles < ActiveRecord::Migration[8.0]
  def up
    change_column :ai_division_summaries, :title, :text
  end

  def down
    change_column :ai_division_summaries, :title, :string
  end
end

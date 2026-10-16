# frozen_string_literal: true

class AddCreatedAtIndexToApiStatistics < ActiveRecord::Migration[8.1]
  def change
    # The index briefly needs the table to itself at the start and end. Give up after 30 seconds rather than wait
    # behind a long query (such as one from Metabase), which would hold up every API request queued behind it.
    reversible { execute "SET SESSION lock_wait_timeout = 30" }

    # The table has ~25M rows. INPLACE builds the index without blocking the
    # inserts that log each API request while it runs.
    add_index :api_statistics, :created_at, algorithm: :inplace
  end
end

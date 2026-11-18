# frozen_string_literal: true

class AddCreatedAtIndexToApiStatistics < ActiveRecord::Migration[8.0]
  # The table has ~25M rows. INPLACE builds the index without blocking the
  # inserts that log each API request while it runs.
  def up
    with_lock_wait_limit { add_index :api_statistics, :created_at, algorithm: :inplace }
  end

  def down
    with_lock_wait_limit { remove_index :api_statistics, :created_at }
  end

  private

  # The index briefly needs the table to itself at the start and end. Give up after 30 seconds rather than wait
  # behind a long query (such as one from Metabase), which would hold up every API request queued behind it.
  # The limit is put back afterwards, so later migrations in the same run aren't affected.
  def with_lock_wait_limit
    execute "SET SESSION lock_wait_timeout = 30"
    yield
  ensure
    execute "SET SESSION lock_wait_timeout = DEFAULT"
  end
end

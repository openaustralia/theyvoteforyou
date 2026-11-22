# frozen_string_literal: true

# The same report as Planning Alerts' and morph.io's db:stats, so the sites can be compared. Counts and sizes come from
# MySQL's information_schema, which is quick but approximate for InnoDB: small tables are counted exactly, and
# EXACT_COUNT=1 counts every table (slow on big ones, such as api_statistics).
namespace :db do
  desc "Show each table's row count and size (EXACT_COUNT=1 for exact counts)"
  task stats: :environment do
    heading_fmt = "%-30s %8s %11s"
    row_fmt     = "%-30s %8d %8.1f MB"

    puts format(heading_fmt, "Table", "Count", "Size")
    puts format(heading_fmt, "-" * 30, "-" * 8, "-" * 11)

    conn = ActiveRecord::Base.connection
    # MySQL 8 otherwise answers from figures cached for up to a day
    conn.execute("SET SESSION information_schema_stats_expiry = 0")
    sql = <<~SQL.squish
      SELECT TABLE_NAME, TABLE_ROWS, (DATA_LENGTH + INDEX_LENGTH) / 1024.0 / 1024.0
      FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = #{conn.quote(conn.current_database)}
    SQL
    table_stats = conn.exec_query(sql).rows.to_h { |name, rows, mb| [name, [rows, mb]] }

    total_mb    = 0.0
    total_count = 0

    conn.tables.sort.each do |table|
      approx_count, mb = table_stats[table]

      count = if ENV["EXACT_COUNT"] || approx_count.to_i < 100
                conn.select_value("SELECT COUNT(*) FROM #{conn.quote_table_name(table)}")
              else
                approx_count
              end

      total_mb    += mb.to_f
      total_count += count
      puts format(row_fmt, table, count, mb.to_f)
    end

    puts format(heading_fmt, "", "=" * 8, "=" * 11)
    puts format(row_fmt, "TOTAL", total_count, total_mb)
    puts "",
         "Status as of #{Time.now.utc}",
         ENV["EXACT_COUNT"] ? "(exact count)" : "(approximate count - set EXACT_COUNT=1 to get exact)"
  end
end

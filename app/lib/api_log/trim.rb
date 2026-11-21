# frozen_string_literal: true

module ApiLog
  # Deletes whole months of api_statistics once Elasticsearch has every call in them (#1874). Elasticsearch keeps the
  # long-term history; api_statistics keeps at least KEEP_FOR, so application:cache:daily_api_usage can still rebuild
  # the admin API usage page's 30 day view from it.
  #
  # Run nightly by application:api_log:nightly (lib/tasks/api_log.rake). A month kept back is tried again the next
  # night.
  module Trim
    KEEP_FOR = 30.days

    # Raised when Elasticsearch can't be reached or answers with an error
    ELASTICSEARCH_ERRORS = [Faraday::Error, Elasticsearch::Transport::Transport::Error].freeze

    # True if every eligible month was trimmed, false if any was kept back
    def self.run
      results = eligible_months.map { |month| trim_month(month) }
      results.exclude?(:kept)
    rescue *ELASTICSEARCH_ERRORS => e
      # Raised before the month's rows are deleted, so nothing unchecked is lost
      say "Stopped, as Elasticsearch couldn't be reached (#{e.class}: #{e.message}). Later months weren't trimmed."
      false
    end

    # Each month, oldest first, that ended KEEP_FOR or more ago, as the UTC start of the month
    def self.eligible_months
      earliest = ApiStatistic.minimum(:created_at)
      return [] unless earliest

      # The first month still kept: the one KEEP_FOR ago is in, as it hasn't been over for that long
      first_kept = (Time.current.utc - KEEP_FOR).beginning_of_month
      months = []
      month = earliest.utc.beginning_of_month
      while month < first_kept
        months << month
        month = month.next_month
      end
      months
    end
    private_class_method :eligible_months

    # :deleted, :kept, or :empty if the month has no rows
    def self.trim_month(month)
      label = month.strftime("%Y-%m")
      first_row_at = ApiStatistic.where(created_at: month...month.next_month).minimum(:created_at)
      unless first_row_at
        say "#{label}: no rows"
        return :empty
      end

      # Only the hours still in api_statistics are compared. A run stopped partway through deleting leaves whole
      # hours (see delete_hour_by_hour), and the calls of the hours it deleted are still in Elasticsearch, so
      # counting the whole month would never match again.
      from = first_row_at.utc.beginning_of_hour
      row_count = ApiStatistic.where(created_at: from...month.next_month).count
      first_count = elasticsearch_count(month, from)
      final_count = first_count
      counts = "#{label}: #{row_count} rows, #{first_count} in Elasticsearch"
      if first_count != row_count
        resend(month)
        final_count = elasticsearch_count(month, from)
        counts += " (#{final_count} after sending again)"
      end

      if final_count == row_count
        delete_hour_by_hour(from, month.next_month)
        say "#{counts}, deleted"
        :deleted
      else
        Sentry.capture_message(
          "api_statistics month kept, as Elasticsearch doesn't have the same calls",
          extra: { month: label, from: from.iso8601, rows: row_count, elasticsearch: final_count }
        )
        say "#{counts}, kept as the counts differ"
        :kept
      end
    end
    private_class_method :trim_month

    # Printed rather than logged, as the rake tasks don't send the log to the terminal or cron's output
    def self.say(line)
      puts line # rubocop:disable Rails/Output
    end
    private_class_method :say

    def self.elasticsearch_count(month, from)
      Index.count(index_for(month), from: from, to: month.next_month)
    end
    private_class_method :elasticsearch_count

    # Each hour is one statement, so it's either all deleted or all still there, and no statement holds locks on the
    # table for long (about 3,000 rows an hour in late 2026)
    def self.delete_hour_by_hour(from, to)
      hour = from
      while hour < to
        ApiStatistic.where(created_at: hour...(hour + 1.hour)).delete_all
        hour += 1.hour
      end
    end
    private_class_method :delete_hour_by_hour

    # The month's own index, or once its year has been combined (#1917) and the monthly index deleted, the year's.
    # A year can be combined before its rows are trimmed, as the backfill does. Checked on every count, as sending
    # the month again can create the monthly index.
    def self.index_for(month)
      monthly = Index.monthly_name(month)
      Index.exists?(monthly) ? monthly : Index.yearly_name(month.year)
    end
    private_class_method :index_for

    # Calls are stored under fixed ids, so sending the month again only replaces what's there. Missing calls are
    # added, but extra ones stay, so a month with more in Elasticsearch than in api_statistics is still kept. Upload
    # won't write into a combined year, so a combined month that's short stays short and is kept.
    def self.resend(month)
      Upload.month(month)
      # So the next count sees what was just sent, rather than waiting for Elasticsearch's own refresh
      Searchkick.client.indices.refresh(index: index_for(month), ignore_unavailable: true)
    end
    private_class_method :resend
  end
end

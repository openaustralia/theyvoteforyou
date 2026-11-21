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

    # Deleted a batch at a time so no single statement holds locks on the table for long
    BATCH_SIZE = 10_000

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
      rows = ApiStatistic.where(created_at: month...month.next_month)
      row_count = rows.count
      if row_count.zero?
        say "#{label}: no rows"
        return :empty
      end

      first_count = elasticsearch_count(month)
      final_count = first_count
      counts = "#{label}: #{row_count} rows, #{first_count} in Elasticsearch"
      if first_count != row_count
        resend(month)
        final_count = elasticsearch_count(month)
        counts += " (#{final_count} after sending again)"
      end

      if final_count == row_count
        rows.in_batches(of: BATCH_SIZE).delete_all
        say "#{counts}, deleted"
        :deleted
      else
        Sentry.capture_message(
          "api_statistics month kept, as Elasticsearch doesn't have the same calls",
          extra: { month: label, rows: row_count, elasticsearch: final_count }
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

    def self.elasticsearch_count(month)
      Index.count(Index.monthly_name(month), from: month, to: month.next_month)
    end
    private_class_method :elasticsearch_count

    # Calls are stored under fixed ids, so sending the month again only replaces what's there. Missing calls are
    # added, but extra ones stay, so a month with more in Elasticsearch than in api_statistics is still kept.
    def self.resend(month)
      Upload.month(month)
      # So the next count sees what was just sent, rather than waiting for Elasticsearch's own refresh
      Searchkick.client.indices.refresh(index: Index.monthly_name(month), ignore_unavailable: true)
    end
    private_class_method :resend
  end
end

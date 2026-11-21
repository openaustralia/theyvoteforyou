# frozen_string_literal: true

module ApiLog
  # Copies past api_statistics rows to their monthly indices (#1916), as the same documents LogApiCallJob sends, so
  # calls copied here and calls sent live look alike. Ids come from the row, so copying a month again replaces its
  # calls rather than counting them twice.
  #
  # Run by application:api_log:upload, and by ApiLog::Trim to send a month again when its counts don't match.
  # Both return false if anything was left undone, so the rake task exits non-zero.
  module Upload
    # Estimated at about 5 MB a request. Each month prints its first request's size, to check this against the 5 to
    # 15 MB Elasticsearch handles comfortably.
    BATCH_SIZE = 10_000

    # How many failed calls a month prints, as one reason is usually shared by all of them
    REASONS_SHOWN = 3

    MONTH_FORMAT = /\A\d{4}-(0[1-9]|1[0-2])\z/

    # Raised when Elasticsearch can't be reached or refuses a request. Every later month would fail the same way, so
    # the run stops rather than reporting each one.
    class Unavailable < StandardError; end

    # from and to are "YYYY-MM" strings, or nil for the earliest or latest month with rows
    def self.run(from:, to:, out: $stdout)
      first_month, last_month = months_with_rows
      unless first_month
        out.puts "api_statistics is empty, so there's nothing to copy"
        return true
      end
      if from.nil? && to.nil?
        out.puts "api_statistics has rows from #{first_month.strftime('%Y-%m')} to #{last_month.strftime('%Y-%m')}. " \
                 "Copying them all; set FROM=YYYY-MM TO=YYYY-MM to copy fewer."
      end

      from_month = from ? parse_month(from) : first_month
      to_month = to ? parse_month(to) : last_month
      raise ArgumentError, "FROM (#{from_month.strftime('%Y-%m')}) is after TO (#{to_month.strftime('%Y-%m')})" if from_month > to_month

      months_between(from_month, to_month).map { |month| copy_month(month, out) }.all?
    rescue ArgumentError => e
      out.puts e.message
      false
    rescue Unavailable => e
      out.puts "Stopped: #{e.message}"
      false
    end

    # Copies the month that month (a Date or Time) falls in, in UTC
    def self.month(month, out: $stdout)
      month = month.utc if month.respond_to?(:utc)
      copy_month(Date.new(month.year, month.month), out)
    rescue Unavailable => e
      out.puts "Stopped: #{e.message}"
      false
    end

    # Not a predicate, despite returning true or false: it does the copying, and says whether all of it went
    def self.copy_month(month, out) # rubocop:disable Naming/PredicateMethod
      label = month.strftime("%Y-%m")
      start = Time.utc(month.year, month.month)
      rows = ApiStatistic.where(created_at: start...start.next_month)
      return true unless rows.exists?

      if elasticsearch { Index.exists?(Index.yearly_name(month.year)) }
        out.puts "#{label}: skipped, as #{month.year} has been combined into #{Index.yearly_name(month.year)}"
        return true
      end

      # Otherwise the first bulk request creates the index, guessing each field's type rather than using MAPPINGS
      index = Index.monthly_name(start)
      elasticsearch { Index.create(index) }

      sent = 0
      failures = []
      unreadable = []
      first_size = nil
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      rows.find_in_batches(batch_size: BATCH_SIZE) do |batch|
        lines = bulk_lines(batch, index, unreadable)
        next if lines.empty?

        body = "#{lines.join("\n")}\n"
        first_size ||= body.bytesize
        response = elasticsearch { Searchkick.client.bulk(body: body) }
        sent += lines.size / 2
        failures.concat(failed_items(response)) if response["errors"]
      end
      seconds = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started

      out.puts "#{label}: sent #{sent} rows to #{index} in #{seconds.round(1)}s " \
               "(first request #{first_size} bytes)"
      report_unreadable(label, unreadable, out) if unreadable.any?
      report_failures(label, failures, sent, out) if failures.any?
      unreadable.empty? && failures.empty?
    end
    private_class_method :copy_month

    def self.months_with_rows
      first, last = ApiStatistic.pick(Arel.sql("MIN(created_at)"), Arel.sql("MAX(created_at)"))
      return unless first

      [first, last].map { |time| Date.new(time.utc.year, time.utc.month) }
    end
    private_class_method :months_with_rows

    def self.parse_month(text)
      raise ArgumentError, "#{text.inspect} isn't a month in the form YYYY-MM, such as 2024-03" unless MONTH_FORMAT.match?(text)

      Date.strptime(text, "%Y-%m")
    end
    private_class_method :parse_month

    def self.months_between(from_month, to_month)
      months = []
      month = from_month
      while month <= to_month
        months << month
        month = month.next_month
      end
      months
    end
    private_class_method :months_between

    # Sent as NDJSON we build ourselves, rather than letting the client do it, so the request's size can be printed.
    # Document.build copes with the odd queries known to be stored (rows from before #1871 are kept as sent), so
    # this is a safety net: a row it still can't build is left out and added to unreadable, rather than stopping the
    # rest of its month being sent.
    def self.bulk_lines(batch, index, unreadable)
      batch.flat_map do |row|
        [{ index: { _index: index, _id: Document.id(row) } }.to_json, Document.build(row).to_json]
      rescue StandardError => e
        unreadable << "#{Document.id(row)}: #{e.class}: #{e.message}"
        []
      end
    end
    private_class_method :bulk_lines

    # The month's Elasticsearch count then falls short of api_statistics, so ApiLog::Trim keeps the month back
    def self.report_unreadable(label, unreadable, out)
      out.puts "#{label}: left out #{unreadable.size} rows that couldn't be made into documents, for example:"
      unreadable.first(REASONS_SHOWN).each { |reason| out.puts "  #{reason}" }
      Sentry.capture_message(
        "ApiLog::Upload: left out #{unreadable.size} unreadable rows for #{label}",
        extra: { examples: unreadable.first(REASONS_SHOWN) }
      )
    end
    private_class_method :report_unreadable

    # A bulk request succeeds as a whole even when some of its calls are rejected, so each item is checked
    def self.failed_items(response)
      response["items"].filter_map do |item|
        result = item["index"]
        "#{result['_id']}: #{result.dig('error', 'type')}: #{result.dig('error', 'reason')}" if result["error"]
      end
    end
    private_class_method :failed_items

    def self.report_failures(label, failures, sent, out)
      out.puts "#{label}: Elasticsearch rejected #{failures.size} of the #{sent} rows, for example:"
      failures.first(REASONS_SHOWN).each { |failure| out.puts "  #{failure}" }
      Sentry.capture_message(
        "ApiLog::Upload: Elasticsearch rejected #{failures.size} of #{sent} rows for #{label}",
        extra: { examples: failures.first(REASONS_SHOWN) }
      )
    end
    private_class_method :report_failures

    def self.elasticsearch
      yield
    rescue Faraday::Error, Elasticsearch::Transport::Transport::Error => e
      Sentry.capture_exception(e)
      raise Unavailable, "Elasticsearch failed: #{e.class}: #{e.message}"
    end
    private_class_method :elasticsearch
  end
end

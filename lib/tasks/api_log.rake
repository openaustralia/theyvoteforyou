# frozen_string_literal: true

# The API call log: api_statistics rows, copied to Elasticsearch for Kibana (see ApiLog).
# Each class's run returns false if anything was left undone, so the task exits non-zero and the Sentry cron
# monitor flags it. Arguments are passed through as given; each class reads and checks its own.
namespace :application do
  namespace :api_log do
    desc "Copy api_statistics to Elasticsearch (FROM=YYYY-MM TO=YYYY-MM; all months if neither) (#1916)"
    task upload: :environment do
      exit 1 unless ApiLog::Upload.run(from: ENV.fetch("FROM", nil), to: ENV.fetch("TO", nil))
    end

    desc "Combine completed years' monthly indices into yearly ones (FROM=YYYY TO=YYYY, ALLOW_UNTRIMMED=1) (#1917)"
    task combine: :environment do
      exit 1 unless ApiLog::Combine.run(
        from: ENV.fetch("FROM", nil), to: ENV.fetch("TO", nil), allow_untrimmed: ENV["ALLOW_UNTRIMMED"] == "1"
      )
    end

    desc "Delete months of api_statistics that ended 30 or more days ago, once they're all in Elasticsearch (#1874)"
    task trim: :environment do
      exit 1 unless ApiLog::Trim.run
    end

    desc "Run nightly from cron: trim, then combine"
    task nightly: :environment do
      # Combine runs even if trimming a month failed, as it only picks years with nothing left to trim
      trimmed = ApiLog::Trim.run
      combined = ApiLog::Combine.run(from: nil, to: nil, allow_untrimmed: false)
      exit 1 unless trimmed && combined
    end
  end
end

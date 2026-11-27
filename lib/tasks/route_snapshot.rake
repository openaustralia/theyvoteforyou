# frozen_string_literal: true

# The routing snapshot asked for in Ian's review of #1849: see
# DivisionSummaryPipeline::RouteSnapshot and spec/fixtures/route_snapshots/README.md.
namespace :ai do
  desc "Write what Stages 1 and 2 decide for every division in the routing snapshot's range, one YAML " \
       "file per year in spec/fixtures/route_snapshots. YEARS=2026 or YEARS=2025-2026 writes only those years."
  task route_snapshot: :environment do
    snapshot = DivisionSummaryPipeline::RouteSnapshot.new
    years = snapshot.years(ENV.fetch("YEARS", nil))

    puts "Checking the database holds every division Hansard records in #{years.to_sentence}..."
    snapshot.check(years)

    years.each do |year|
      result = snapshot.write(year)
      failed = result[:errors].positive? ? ", #{result[:errors]} with errors" : ""
      puts "#{year}: #{result[:divisions]} divisions#{failed}, written to " \
           "#{snapshot.path(year).relative_path_from(Rails.root)}"
      next if result[:changed_hansard].empty?

      puts "  Hansard has changed for #{result[:changed_hansard].size} days since this file was last written, so " \
           "changed blocks may come from Hansard rather than code (README.md, \"When the files change with no " \
           "code change\"):"
      result[:changed_hansard].each { |day| puts "    #{day}" }
    end
  rescue DivisionSummaryPipeline::RouteSnapshot::Refused => e
    abort e.message
  end
end

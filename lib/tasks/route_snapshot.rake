# frozen_string_literal: true

# The routing snapshot: a record of what the AI summary pipeline's rule-based steps (Stages 1 and 2)
# find and decide for every division, one file per year, saved with the code so `git diff` shows what a
# rule change moved. This file only reads what was typed and prints the results. The work is done in
# app/services/division_summary_pipeline/snapshot/route_snapshot.rb, and how to use it is in
# spec/route_snapshots/README.md.
namespace :ai do
  desc "Write what Stages 1 and 2 decide for every division, one YAML file per year in spec/route_snapshots. " \
       "Rewrites every year that already has a file; YEARS=2026 or YEARS=2025-2026 writes those years instead."
  task route_snapshot: :environment do
    snapshot = DivisionSummaryPipeline::RouteSnapshot.new
    years = snapshot.years(ENV.fetch("YEARS", nil))

    # Every year is checked before any is written, so if the check stops the task, all the files are
    # left as they were.
    puts "Checking the database holds every division Hansard records in #{years.to_sentence}..."
    snapshot.check(years)

    years.each do |year|
      result = snapshot.write(year)
      failed = result[:errors].positive? ? ", #{result[:errors]} with errors" : ""
      puts "#{year}: #{result[:divisions]} divisions#{failed}, written to " \
           "#{snapshot.path(year).relative_path_from(Rails.root)}"
      next if result[:changed_hansard].empty?

      changed = result[:changed_hansard].size
      puts "  Hansard has changed for #{changed} #{'day'.pluralize(changed)} since this file was last written, so " \
           "changed entries may come from Hansard rather than code (README.md, \"When the files change with no " \
           "code change\"):"
      result[:changed_hansard].each { |day| puts "    #{day}" }
    end
  # A planned stop, such as a YEARS= it can't use, missing divisions or a failed download: print the
  # message, which says what to do, without Ruby's error details.
  rescue DivisionSummaryPipeline::RouteSnapshot::Refused, DivisionSummaryPipeline::HansardStore::DownloadFailed => e
    abort e.message
  end
end

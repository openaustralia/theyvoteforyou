# frozen_string_literal: true

require "yaml"

module DivisionSummaryPipeline
  # The routing snapshot (rake ai:route_snapshot): Stages 1 and 2 run over every division in a
  # date range, one SnapshotRecord block per division, written as one YAML file per year in
  # spec/fixtures/route_snapshots. The files are committed, so `git diff` shows what a change to
  # Stage 1 or Stage 2 did across real divisions, and the committed version is the expected
  # result. Asked for in Ian's review of #1849; the routine for using it is in that folder's
  # README.md.
  #
  # The range lives in the folder's settings.yml, saved with the code, so every run of one commit
  # covers the same divisions. Moving it is a change of its own.
  class RouteSnapshot
    FOLDER = Rails.root.join("spec/fixtures/route_snapshots")
    YEARS = /\A(\d{4})(?:\s*-\s*(\d{4}))?\z/

    # A YEARS value the task can't use, or a year outside the range. The task stops with the message.
    class Refused < StandardError; end

    attr_reader :range

    def initialize(folder: FOLDER, store: HansardStore.new)
      @folder = Pathname(folder)
      @store = store
      settings = YAML.safe_load_file(@folder.join("settings.yml"), permitted_classes: [Date])
      @range = Date.parse(settings.dig("range", "from").to_s)..Date.parse(settings.dig("range", "to").to_s)
    end

    # The years to write: every year the range touches, or those YEARS names ("2026", "2025-2026").
    # A year outside the range is refused rather than quietly added, so the files and settings.yml
    # never disagree.
    def years(wanted = nil)
      all = (range.first.year..range.last.year).to_a
      return all if wanted.blank?

      match = wanted.to_s.strip.match(YEARS)
      raise Refused, "YEARS must be a year (2026) or a range of years (2025-2026), not #{wanted.inspect}." unless match

      chosen = (match[1].to_i..(match[2] || match[1]).to_i).to_a
      raise Refused, "YEARS #{wanted} has no years in it: write the earlier year first." if chosen.empty?

      outside = chosen - all
      return chosen if outside.empty?

      raise Refused, "#{outside.join(', ')} is outside the range in settings.yml (#{range.first} to " \
                     "#{range.last}). To include it, change the range there first, then run again."
    end

    # Writes the year's file and returns the number of divisions in it and how many failed.
    def write(year)
      divisions = Division.where(date: dates(year)).sort_by { |division| [division.date, division.house, division.number] }
      blocks = divisions.to_h { |division| [SnapshotRecord.key(division), block(division)] }
      path(year).write(header(year) + YAML.dump({ "divisions" => blocks }, line_width: -1))
      { divisions: blocks.size, errors: blocks.count { |_key, entry| entry.key?("error") } }
    end

    def path(year)
      folder.join("#{year}.yml")
    end

    private

    attr_reader :folder, :store

    def dates(year)
      [range.first, Date.new(year, 1, 1)].max..[range.last, Date.new(year, 12, 31)].min
    end

    # A division Stage 1 or 2 fails on is recorded with the error rather than stopping the run,
    # since the failure is itself a result. Memory addresses are masked so the line is the same
    # from run to run.
    def block(division)
      SnapshotRecord.build(ContextBuilder.build(division, xml_content: store.raw(division.house, division.date),
                                                          xml_fetcher: store.fetcher))
    rescue StandardError => e
      { "error" => "#{e.class}: #{e.message.gsub(/0x\h+/, '0x...')}" }
    end

    def header(year)
      <<~TEXT
        # Routing snapshot for #{year}: what Stages 1 and 2 of the AI division summary pipeline decide for
        # every division, written by `rake ai:route_snapshot`. Don't edit it by hand: rerun the task and
        # commit the result. How to read it, and when to rerun it: README.md in this folder.
      TEXT
    end
  end
end

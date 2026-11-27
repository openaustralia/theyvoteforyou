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
  # The range and the Parliaments live in the folder's settings.yml, saved with the code, so every
  # run of one commit covers the same divisions. Changing it is a change of its own.
  class RouteSnapshot
    FOLDER = Rails.root.join("spec/fixtures/route_snapshots")
    YEARS = /\A(\d{4})(?:\s*-\s*(\d{4}))?\z/

    # Settings, a YEARS value or a database the task can't use. The task stops with the message.
    class Refused < StandardError; end

    attr_reader :range

    def initialize(folder: FOLDER, store: HansardStore.new)
      @folder = Pathname(folder)
      @store = store
      settings = YAML.safe_load_file(@folder.join("settings.yml"), permitted_classes: [Date])
      @range = Date.parse(settings.dig("range", "from").to_s)..Date.parse(settings.dig("range", "to").to_s)
      @parliaments = settings.fetch("parliaments", {}).to_h { |number, from| [Integer(number), Date.parse(from.to_s)] }
      first = @parliaments.values.min
      return if first && first <= range.first

      raise Refused, "The range in settings.yml starts on #{range.first}, before the first Parliament listed " \
                     "there. Add the Parliament that date falls in, then run again."
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

    # Refuses when the database is missing divisions Hansard records in these years
    # (DivisionCountCheck). The task checks every year before writing any, so a refusal leaves all
    # the files as they were.
    def check(years)
      years.each { |year| DivisionCountCheck.new(store).call(dates(year).to_a) }
    end

    # Writes the year's file. Returns how many divisions are in it, how many failed, and the days
    # whose Hansard has changed since the file was last written ("senate/2026-09-17 (proof, now final)").
    def write(year)
      before = saved_hansard_days(year)
      read = Set.new
      blocks = divisions(year).to_h do |division|
        entry, days = block(division)
        read.merge(days)
        [SnapshotRecord.key(division), entry]
      end
      days = read.sort.index_with { |day| store.describe(*day.split("/")) }
      path(year).write(header(year) + YAML.dump({ "hansard_days" => days, "divisions" => blocks }, line_width: -1))
      { divisions: blocks.size, errors: blocks.count { |_key, entry| entry.key?("error") },
        changed_hansard: SnapshotChanges.hansard_changes(before, days) }
    end

    def path(year)
      folder.join("#{year}.yml")
    end

    # The Parliament a date falls in: the latest in settings.yml to begin on or before it.
    def parliament(date)
      parliaments.select { |_number, from| from <= date }.max_by { |_number, from| from }.first
    end

    private

    attr_reader :folder, :store, :parliaments

    def dates(year)
      [range.first, Date.new(year, 1, 1)].max..[range.last, Date.new(year, 12, 31)].min
    end

    def divisions(year)
      Division.where(date: dates(year)).sort_by { |division| [division.date, division.house, division.number] }
    end

    # The division's block, and the sitting days Stage 1 read for it as "house/date": its own and
    # every earlier day EarlierDebate opened, the days whose Hansard could change the block.
    # A division Stage 1 or 2 fails on is recorded with the error rather than stopping the run,
    # since the failure is itself a result. Memory addresses are masked so the line is the same
    # from run to run.
    def block(division)
      read = []
      own = store.raw(division.house, division.date)
      read << division.date.to_s if own
      fetcher = ->(house, date) { store.fetcher.call(house, date).tap { |document| read << date.to_s if document } }
      packet = ContextBuilder.build(division, xml_content: own, xml_fetcher: fetcher)
      days = read.uniq.sort.map { |date| "#{division.house}/#{date}" }
      [SnapshotRecord.build(packet, sources(division, days)), days]
    rescue StandardError => e
      [{ "error" => "#{e.class}: #{e.message.gsub(/0x\h+/, '0x...')}" }, []]
    end

    # What the block records from outside Stages 1 and 2.
    def sources(division, days)
      { "parliament" => parliament(division.date),
        "hansard" => store.describe(division.house, division.date)&.fetch("version"), "hansard_read" => days }
    end

    def saved_hansard_days(year)
      return {} unless path(year).exist?

      YAML.safe_load_file(path(year), permitted_classes: [Date]).fetch("hansard_days", nil) || {}
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

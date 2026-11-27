# frozen_string_literal: true

require "yaml"

module DivisionSummaryPipeline
  # Runs the routing snapshot, the task in lib/tasks/route_snapshot.rake.
  #
  # The AI summary pipeline starts with two steps that use fixed rules, not AI. Stage 1 reads a
  # division's Hansard (the official record of what was said in parliament) and finds the question
  # that was voted on, the motion and who moved it. Stage 2 uses what Stage 1 found to decide which
  # summary template fits the vote. This runs both steps over every division in a date range and
  # writes down what they found and decided: one entry per division (made by snapshot_record.rb), one
  # file per year, in spec/route_snapshots/.
  #
  # Those files are saved in git with the code. After someone changes a rule, running the task again
  # and looking at `git diff` shows exactly which divisions changed. spec/route_snapshots/README.md
  # explains how to use it.
  #
  # The date range and the list of Parliaments come from spec/route_snapshots/settings.yml, which is
  # saved with the code, so every run of the same code covers the same divisions.
  class RouteSnapshot
    # Where the year files and settings.yml live.
    FOLDER = Rails.root.join("spec/route_snapshots")
    # What YEARS= may be: one year ("2026") or a range of years ("2025-2026").
    YEARS = /\A(\d{4})(?:\s*-\s*(\d{4}))?\z/

    # Raised when the task can't run as asked: a YEARS= value it can't use, a range in settings.yml
    # that starts before the first Parliament listed there, a database missing divisions, or Hansard
    # that couldn't be downloaded. The task stops and prints the message, which says what to fix.
    class Refused < StandardError; end

    attr_reader :range

    # Reads settings.yml. Stops if the range starts before the first Parliament listed there, since
    # every entry needs a Parliament number. The tests pass in their own folder and their own local
    # copy of Hansard (the store, from hansard_store.rb).
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

    # Which years to write. With no YEARS=, every year the range covers. With YEARS=, just those
    # years, but a year outside the range is refused rather than quietly added, so the files and
    # settings.yml never disagree.
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

    # The division count check (division_count_check.rb): stops if the database is missing any
    # division Hansard records in these years. The task checks every year before writing any, so if it
    # stops, all the files are left as they were.
    def check(years)
      years.each { |year| DivisionCountCheck.new(store).call(dates(year).to_a) }
    end

    # Writes one year's file: a list of every Hansard day read, then one entry per division. Returns
    # how many divisions it wrote, how many failed, and any Hansard days whose fingerprint has changed
    # since the file was last written, such as "senate/2026-09-17 (proof, now final)".
    #
    # If any day's Hansard couldn't be downloaded along the way, it stops without writing, because the
    # entries that needed that day could be wrong.
    def write(year)
      before = saved_hansard_days(year)
      read = Set.new
      blocks = divisions(year).to_h do |division|
        entry, days = block(division)
        read.merge(days)
        [SnapshotRecord.key(division), entry]
      end
      refuse_after_failed_downloads(year)
      days = read.sort.index_with { |day| store.describe(*day.split("/")) }
      path(year).write(header(year) + YAML.dump({ "hansard_days" => days, "divisions" => blocks }, line_width: -1))
      { divisions: blocks.size, errors: blocks.count { |_key, entry| entry.key?("error") },
        changed_hansard: changed_hansard(before, days) }
    end

    # The year's file, for example spec/route_snapshots/2026.yml.
    def path(year)
      folder.join("#{year}.yml")
    end

    # Which Parliament a date falls in: the latest one in settings.yml that began on or before it. For
    # example, 27 March 2025 is in the 47th and 22 July 2025 is in the 48th.
    def parliament(date)
      parliaments.select { |_number, from| from <= date }.max_by { |_number, from| from }.first
    end

    private

    attr_reader :folder, :store, :parliaments

    # The days of the year inside the range: for 2026, only 1 January to 31 October.
    def dates(year)
      [range.first, Date.new(year, 1, 1)].max..[range.last, Date.new(year, 12, 31)].min
    end

    # The year's divisions from the database, in date, house and number order, so the file's order
    # never changes.
    def divisions(year)
      Division.where(date: dates(year)).sort_by { |division| [division.date, division.house, division.number] }
    end

    # One division's entry, and the sitting days Stage 1 read for it, written as "house/date": the
    # division's own day, plus any earlier day it looked back to for earlier parts of the debate. A
    # change to any of those days' Hansard could change the entry.
    #
    # If Stage 1 or 2 fails on a division, its entry records the error instead of stopping the run,
    # because the failure is a result worth seeing. Some error messages contain a memory address (like
    # 0x7f3a...), which differs every run, so it is replaced with "0x...".
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

    # The fields an entry gets from outside Stages 1 and 2: the Parliament, whether the day's Hansard
    # is final, a proof or unmarked, and the sitting days read.
    def sources(division, days)
      { "parliament" => parliament(division.date),
        "hansard" => store.describe(division.house, division.date)&.fetch("version"), "hansard_read" => days }
    end

    def refuse_after_failed_downloads(year)
      return if store.failures.empty?

      raise Refused, "Couldn't download Hansard for #{store.failures.size} " \
                     "#{'day'.pluralize(store.failures.size)}, so #{path(year).basename} wasn't written:\n  " \
                     "#{store.failures.join("\n  ")}\nCheck the internet connection, then run the task again."
    end

    # The Hansard days listed in the year's file before this run, to compare fingerprints with. Empty
    # if there is no file yet.
    def saved_hansard_days(year)
      return {} unless path(year).exist?

      YAML.safe_load_file(path(year), permitted_classes: [Date]).fetch("hansard_days", nil) || {}
    end

    # The Hansard days listed both before and after this run whose fingerprint differs, written like
    # "senate/2026-09-17 (proof, now final)".
    def changed_hansard(before, now)
      now.filter_map do |day, about|
        was = before[day]
        next if was.nil? || was["fingerprint"] == about["fingerprint"]

        version = was["version"] == about["version"] ? about["version"] : "#{was['version']}, now #{about['version']}"
        "#{day} (#{version})"
      end
    end

    # The note at the top of each year's file.
    def header(year)
      <<~TEXT
        # Routing snapshot for #{year}: what Stages 1 and 2 of the AI division summary pipeline decide for
        # every division, written by `rake ai:route_snapshot`. Don't edit it by hand: rerun the task and
        # commit the result. How to read it, and when to rerun it: README.md in this folder.
      TEXT
    end
  end
end

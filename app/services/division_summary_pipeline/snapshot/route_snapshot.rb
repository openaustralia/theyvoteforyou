# frozen_string_literal: true

require "yaml"

module DivisionSummaryPipeline
  # Runs the routing snapshot, the task in lib/tasks/route_snapshot.rake.
  #
  # The AI summary pipeline starts with two steps that use fixed rules, not AI. Stage 1 reads a
  # division's Hansard (the official record of what was said in parliament) and finds the question
  # that was voted on, the motion and who moved it. Stage 2 uses what Stage 1 found to decide which
  # summary template fits the vote. This runs both steps over every division in a year and
  # writes down what they found and decided: one entry per division (made by snapshot_record.rb), one
  # file per year, in spec/route_snapshots/.
  #
  # Those files are saved in git with the code. After someone changes a rule, running the task again
  # and looking at `git diff` shows exactly which divisions changed. spec/route_snapshots/README.md
  # explains how to use it.
  #
  # Each file always covers a whole calendar year (the current year up to today), so a year's file
  # means the same thing to everyone who runs the task.
  class RouteSnapshot
    # Where the year files live.
    FOLDER = Rails.root.join("spec/route_snapshots")
    # What YEARS= may be: one year ("2026") or a range of years ("2025-2026").
    YEARS = /\A(\d{4})(?:\s*-\s*(\d{4}))?\z/

    # Raised when the task can't run as asked: a YEARS= value it can't use, no year files to rewrite,
    # a database missing divisions, or Hansard that couldn't be downloaded. The task stops and prints
    # the message, which says what to fix.
    class Refused < StandardError; end

    # The tests pass in their own folder and their own local copy of Hansard (the store, from
    # hansard_store.rb).
    def initialize(folder: FOLDER, store: HansardStore.new)
      @folder = Pathname(folder)
      @store = store
    end

    # Which years to write. With no YEARS=, every year that already has a file in the folder, so a run
    # rewrites the whole logbook. With YEARS=, just those years, which is also how a new year's file is
    # started. A year that hasn't begun yet is refused.
    def years(wanted = nil)
      return saved_years if wanted.blank?

      match = wanted.to_s.strip.match(YEARS)
      raise Refused, "YEARS must be a year (2026) or a range of years (2025-2026), not #{wanted.inspect}." unless match

      chosen = (match[1].to_i..(match[2] || match[1]).to_i).to_a
      raise Refused, "YEARS #{wanted} has no years in it: write the earlier year first." if chosen.empty?
      raise Refused, "YEARS #{wanted} includes a year that hasn't begun yet." if chosen.last > Date.current.year

      chosen
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

    private

    attr_reader :folder, :store

    # The years that already have a file in the folder, such as 2025.yml and 2026.yml.
    def saved_years
      years = folder.glob("*.yml").filter_map { |file| file.basename(".yml").to_s[/\A\d{4}\z/]&.to_i }.sort
      return years if years.any?

      raise Refused, "There are no year files in #{folder.relative_path_from(Rails.root)} yet. Name the years " \
                     "to write, for example YEARS=2026."
    end

    # The year's days: the whole calendar year, or up to today for the current year.
    def dates(year)
      Date.new(year, 1, 1)..[Date.new(year, 12, 31), Date.current].min
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

    # The fields an entry gets from outside Stages 1 and 2: whether the day's Hansard is final, a proof
    # or unmarked, and the sitting days read.
    def sources(division, days)
      { "hansard" => store.describe(division.house, division.date)&.fetch("version"), "hansard_read" => days }
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

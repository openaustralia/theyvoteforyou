# frozen_string_literal: true

module DivisionSummaryPipeline
  # Checks that the database holds every division that Hansard records on the snapshot's dates,
  # before the snapshot writes anything (route_snapshot.rb calls it). The snapshot starts from the
  # divisions in the database, so without this a day, month or year that was never loaded would
  # simply be left out of the file, with no warning.
  #
  # It goes through every day in both houses, the same way the nightly loader does
  # (app/lib/data_loader/debates.rb), and compares the number of divisions in that day's Hansard with
  # the number stored for it. Days with no Hansard (weekends and other days parliament didn't sit)
  # are remembered by the local copy of Hansard (hansard_store.rb), so each is asked about only once,
  # except days less than 14 days old.
  class DivisionCountCheck
    # How many days with missing divisions to list in the message before it says "and N more days".
    LISTED_DAYS = 10

    # store is the local copy of Hansard (hansard_store.rb).
    def initialize(store)
      @store = store
    end

    # Stops the task, printing the days affected and the command that loads them, if the database is
    # missing any of the divisions that Hansard records on these dates. Does nothing if none are missing.
    def call(dates)
      stored = Division.where(date: dates).group(:house, :date).count
      short = dates.flat_map do |date|
        House.australian.filter_map do |house|
          count = stored.fetch([house, date], 0)
          missing = in_hansard(house, date, count) - count
          [house, date, missing] if missing.positive?
        end
      end
      raise RouteSnapshot::Refused, message(short) if short.any?
    end

    private

    attr_reader :store

    # How many divisions the day's Hansard records. If the database has divisions on a day that was
    # remembered as having no Hansard, that memory is out of date (they were loaded from its Hansard),
    # so the day is asked about again.
    def in_hansard(house, date, stored)
      store.raw(house, date, recheck_missing: stored.positive?)&.scan(/<division\s/)&.size || 0
    end

    # The message printed when divisions are missing, ending with the command that loads them.
    def message(short)
      first, last = short.map { |_house, date, _missing| date }.minmax
      listed = short.first(LISTED_DAYS).map { |house, date, missing| "  #{house} #{date}: #{missing} missing" }
      listed << "  and #{short.size - LISTED_DAYS} more days" if short.size > LISTED_DAYS
      days = "#{short.size} #{'day'.pluralize(short.size)}"
      <<~TEXT
        The database is missing divisions that Hansard records, on #{days} (each house counted
        separately) from #{first} to #{last}:
        #{listed.join("\n")}
        Load them, then run again (this also reloads any days in between that are already loaded):
          bin/rake "application:load:divisions[#{first},#{last}]"
      TEXT
    end
  end
end

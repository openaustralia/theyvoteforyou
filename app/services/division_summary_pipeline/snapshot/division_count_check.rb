# frozen_string_literal: true

module DivisionSummaryPipeline
  # The routing snapshot's check that the database holds every division Hansard records on the
  # dates it covers (RouteSnapshot#check). The snapshot starts from the divisions in the database,
  # so a day, month or year never loaded would otherwise just be left out of the file.
  #
  # It walks every day in both houses, as the loader does (DataLoader::Debates.load!), and counts
  # each day's <division> elements against the divisions stored for it. Days with no Hansard are
  # remembered by HansardStore, so only the first run asks about each one.
  class DivisionCountCheck
    LISTED_DAYS = 10

    def initialize(store)
      @store = store
    end

    # Raises RouteSnapshot::Refused, with the command that loads them, when the database is missing
    # any of the divisions Hansard records on these dates.
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

    # A day with divisions in the database had Hansard when they were loaded, so a "no Hansard"
    # remembered for it is out of date and is asked again.
    def in_hansard(house, date, stored)
      store.raw(house, date, recheck_missing: stored.positive?)&.scan(/<division\s/)&.size || 0
    end

    def message(short)
      first, last = short.map { |_house, date, _missing| date }.minmax
      listed = short.first(LISTED_DAYS).map { |house, date, missing| "  #{house} #{date}: #{missing} missing" }
      listed << "  and #{short.size - LISTED_DAYS} more days" if short.size > LISTED_DAYS
      <<~TEXT
        The database is missing divisions that Hansard records, on #{short.size} sitting days from #{first} to #{last}:
        #{listed.join("\n")}
        Load them, then run again (this also reloads any days in between that are already loaded):
          bin/rake "application:load:divisions[#{first},#{last}]"
      TEXT
    end
  end
end

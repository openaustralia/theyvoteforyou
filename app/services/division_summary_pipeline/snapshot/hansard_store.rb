# frozen_string_literal: true

require "nokogiri"

module DivisionSummaryPipeline
  # Sitting days' ParlParse XML for the routing snapshot (RouteSnapshot), downloaded once from the
  # same place the nightly loader reads (DataLoader::Debates.xml_url) and kept under tmp/hansard_xml
  # exactly as published. Every run then reads the same Hansard, so two runs with no code change
  # between them agree, and a run doesn't spend hours fetching: EarlierDebate looks back up to 70
  # days for every division.
  #
  # A day with no XML (a 404, so not a sitting day) is remembered with an empty ".missing" file.
  # Delete the folder, or a day's files, to fetch them again.
  class HansardStore
    # How many parsed days to keep in memory. Divisions are read in date order and EarlierDebate
    # looks back at most 70 days, so this covers the look-back without holding a year of parsed
    # documents, which runs to gigabytes.
    PARSED_DAYS = 40

    def initialize(dir: Rails.root.join("tmp/hansard_xml"), agent: Mechanize.new)
      @dir = Pathname(dir)
      @agent = agent
      @parsed = {}
    end

    # The day's XML as published, or nil when there is none.
    def raw(house, date)
      file = path(house, date, "xml")
      return file.read if file.exist?
      return nil if path(house, date, "missing").exist?

      download(house, date)
    end

    # The xml_fetcher ContextBuilder takes for earlier sitting days: (house, date) to a parsed
    # document, or nil.
    def fetcher
      ->(house, date) { parsed(house, date.to_s) }
    end

    private

    attr_reader :dir, :agent

    def path(house, date, extension)
      dir.join("#{house}-#{date}.#{extension}")
    end

    def download(house, date)
      FileUtils.mkdir_p(dir)
      body = agent.get(DataLoader::Debates.xml_url(house, date.to_s)).body
      path(house, date, "xml").binwrite(body)
      path(house, date, "xml").read
    rescue Mechanize::ResponseCodeError => e
      raise if e.response_code != "404"

      FileUtils.touch(path(house, date, "missing"))
      nil
    end

    def parsed(house, date)
      key = "#{house}-#{date}"
      return @parsed[key] = @parsed.delete(key) if @parsed.key?(key)

      @parsed.shift if @parsed.size >= PARSED_DAYS
      text = raw(house, date)
      @parsed[key] = text && Nokogiri::XML(text)
    end
  end
end

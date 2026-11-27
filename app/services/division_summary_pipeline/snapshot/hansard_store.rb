# frozen_string_literal: true

require "digest"
require "nokogiri"

module DivisionSummaryPipeline
  # The routing snapshot's local copy of Hansard, used by route_snapshot.rb and
  # division_count_check.rb. Each sitting day's Hansard, one file per house per day, is downloaded
  # once from the same place the nightly loader gets it (OAF's data site, through
  # app/lib/data_loader/debates.rb), and kept in tmp/hansard_xml/ exactly as published. Every run then
  # reads the same Hansard, so two runs with no code change agree. It also saves time: Stage 1 can
  # look back through up to 70 days of earlier debate for each division, and those days are read from
  # here instead of being downloaded again.
  #
  # A day with no Hansard (the site says the file doesn't exist, because parliament didn't sit) is
  # remembered with an empty file ending in ".missing", so it isn't asked about again. Delete the
  # folder, or a day's files, to download them again: for example, to get the final version of a day
  # kept here as a proof.
  #
  # Any other download problem, such as a dropped internet connection, is noted in failures, so the
  # snapshot can refuse to write a year's file that might be wrong without that day.
  class HansardStore
    # The error given when a day's Hansard can't be downloaded for any reason other than there being none.
    class DownloadFailed < StandardError; end

    # How many days of Hansard to keep ready in memory, already read into a form Stage 1 can search.
    # These are the days used most recently (days with no Hansard count too). A day that has dropped
    # out is simply read from tmp/hansard_xml/ again, so this only affects speed, and it keeps memory
    # use low: holding a whole year this way would take far more memory.
    PARSED_DAYS = 40
    # How many of each fingerprint's 64 characters go in the year files (describe, below, explains
    # fingerprints).
    FINGERPRINT_LENGTH = 16
    # A day less than this many days old is never remembered as having no Hansard, because its
    # Hansard may just not be published yet. It is asked about again on the next run.
    RECENT_DAYS = 14
    # The marks that say whether a day's Hansard is final. While Parliament has published only a proof
    # (a draft) of a day, its file is marked proof="1"; once it is final, proof="0". Older files have no
    # mark at all, which the snapshot calls "unknown".
    VERSIONS = { "1" => "proof", "0" => "final" }.freeze

    # Normally the files are kept in tmp/hansard_xml/. The tests hand it a practice folder instead, so
    # they never touch the real files.
    def initialize(dir: Rails.root.join("tmp/hansard_xml"))
      @dir = Pathname(dir)
      @agent = Mechanize.new
      @parsed = {}
      @described = {}
      @failures = []
    end

    # The days that couldn't be downloaded so far, each with the reason, such as
    # "senate/2026-09-17 (SocketError: Failed to open TCP connection)".
    attr_reader :failures

    # The day's Hansard as published, downloading it the first time, or nothing if the day has none.
    # recheck_missing asks again about a day remembered as having none. The division count check uses
    # it when the database has divisions on that day, which means its Hansard was published after the
    # day was first asked about.
    def raw(house, date, recheck_missing: false)
      file = path(house, date, "xml")
      return file.read if file.exist?
      return nil if path(house, date, "missing").exist? && !recheck_missing

      download(house, date)
    end

    # Whether the day's Hansard is final, a proof or unknown, and its fingerprint: a short code worked
    # out from every character of the file (the start of its SHA-256 hash). The same file always gives
    # the same code, and a change anywhere in the file gives a different one. Nothing if the day has no
    # Hansard.
    def describe(house, date)
      @described["#{house}/#{date}"] ||= raw(house, date)&.then do |text|
        { "version" => VERSIONS.fetch(text[/<debates\b[^>]*\bproof="(\d)"/, 1], "unknown"),
          "fingerprint" => Digest::SHA256.hexdigest(text)[0, FINGERPRINT_LENGTH] }
      end
    end

    # What Stage 1 (context/context_builder.rb) uses to read earlier sitting days when it looks back
    # through a debate: give it a house and a date, and it returns that day's Hansard ready to search,
    # or nothing if the day has none.
    def fetcher
      ->(house, date) { parsed(house, date.to_s) }
    end

    private

    attr_reader :dir, :agent

    # Where a day's file is kept, for example tmp/hansard_xml/senate-2026-09-17.xml.
    def path(house, date, extension)
      dir.join("#{house}-#{date}.#{extension}")
    end

    # Downloads a day's Hansard and keeps it. It is saved under a temporary name first and renamed
    # once complete, so a run stopped halfway can't leave half a day behind. If the site says there's
    # no file for that day, that is remembered instead (unless the day is recent). Any other problem
    # is noted in failures and given as an error, rather than being mistaken for a day without Hansard.
    def download(house, date)
      FileUtils.mkdir_p(dir)
      body = agent.get(DataLoader::Debates.xml_url(house, date.to_s)).body
      path(house, date, "partial").binwrite(body)
      path(house, date, "partial").rename(path(house, date, "xml"))
      FileUtils.rm_f(path(house, date, "missing"))
      path(house, date, "xml").read
    rescue Mechanize::ResponseCodeError => e
      return failed(house, date, e) if e.response_code != "404"

      FileUtils.touch(path(house, date, "missing")) unless recent?(date)
      nil
    rescue StandardError => e
      failed(house, date, e)
    end

    # Notes the day in failures, then gives the error.
    def failed(house, date, error)
      failures << "#{house}/#{date} (#{error.class}: #{error.message})"
      raise DownloadFailed, "Couldn't download Hansard for #{house} #{date} (#{error.class}: #{error.message})."
    end

    def recent?(date)
      Date.parse(date.to_s) >= Date.current - RECENT_DAYS
    end

    # A day's Hansard read into a searchable form, kept in memory for the next time it's asked for.
    # When PARSED_DAYS days are already held, the one used longest ago is dropped to make room.
    def parsed(house, date)
      key = "#{house}-#{date}"
      return @parsed[key] = @parsed.delete(key) if @parsed.key?(key)

      @parsed.shift if @parsed.size >= PARSED_DAYS
      text = raw(house, date)
      @parsed[key] = text && Nokogiri::XML(text)
    end
  end
end

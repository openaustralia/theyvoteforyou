# frozen_string_literal: true

# Drafts AI division summaries with a model running on your own machine (LocalModelClient), newest
# first, one sitting day at a time, and writes one file per division (LocalDraftFile) ready to zip
# and hand over for upload. Run by `rake ai:draft_local`; docs/local-ai-drafts.md explains the setup.
#
# A day's divisions are loaded into the local database only when the run reaches that day, so the
# first draft arrives in minutes rather than after every sitting day since 2006 has been fetched.
# A division that already has a file is skipped, so a run can be stopped at any time and the same
# command carries on where it left off.
class LocalDraftRun
  # The first sitting day in the ParlParse XML at data.openaustralia.org.au, for both houses
  # (checked 12 October 2026): where a run given no start date goes back to.
  EARLIEST = Date.new(2006, 2, 7)

  # representatives/2026-09-17/3, on its own or at the end of the division's full URL.
  SLUG = %r{(#{House.australian.join('|')})/(\d{4}-\d{2}-\d{2})/(\d+)/?\z}

  # The house, date and number a slug or division URL names, or nil when it names none.
  def self.parse_slug(text)
    match = SLUG.match(text.to_s.strip) or return nil
    [match[1], Date.iso8601(match[2]), match[3].to_i]
  rescue Date::Error
    nil
  end

  # DIVISION= named no division, or one Hansard doesn't have.
  class UnknownDivision < StandardError; end

  # FROM= was after TO=, so there is nothing between them to go back over.
  class EmptyRange < StandardError; end

  attr_reader :counts

  # loader: loads a sitting day's divisions into the database; a spec passes its own.
  def initialize(client:, houses: House.australian, root: LocalDraftFile::ROOT, force: false, retry_failed: false,
                 cache: LocalHansardCache.new, out: $stdout, loader: ->(date) { DataLoader::Debates.load!(date) })
    @client = client
    @houses = houses
    @root = Pathname(root)
    @force = force
    @retry_failed = retry_failed
    @cache = cache
    @out = out
    @loader = loader
    @counts = Hash.new(0)
  end

  # Every division from `to` back to `from`, newest first.
  def run(from: EARLIEST, to: Date.current)
    raise EmptyRange, "FROM #{from} is after TO #{to}; the run goes back from TO to FROM" if from > to

    to.downto(from) { |date| draft_day(date) }
    report_totals
  end

  # One division, named by its slug or URL. Unless forced, one already drafted is left alone.
  def run_one(slug)
    house, date, number = self.class.parse_slug(slug)
    raise UnknownDivision, "#{slug} doesn't name a division; try representatives/2026-09-17/3" unless house

    ensure_loaded(house, date)
    division = Division.find_by(house: house, date: date, number: number)
    raise UnknownDivision, "Hansard has no division #{house}/#{date}/#{number}" unless division

    out.puts "#{slug_of(division)}: skipped, as it already has a file; FORCE=1 drafts it again" if draft(division) == :skipped
    report_totals
  end

  private

  attr_reader :client, :houses, :root, :force, :retry_failed, :cache, :out, :loader

  def model_id
    @model_id ||= client.model_id
  end

  def draft_day(date)
    houses.each do |house|
      next unless ensure_loaded(house, date)

      Division.where(house: house, date: date).order(number: :desc).each { |division| draft(division) }
    end
  end

  # Whether the house's divisions for that day are all in the local database, loading the day
  # first when they aren't. A day already in the database may be only part of what Hansard holds
  # (a run stopped in the middle of loading it), so the day's own count in the cached XML says
  # whether anything is still missing. Loading saves through Searchkick's callbacks, which would
  # need Elasticsearch running; drafting doesn't use the search index, so they're off. A day that
  # can't be loaded is skipped and tried again on the next run.
  def ensure_loaded(house, date)
    loaded = Division.where(house: house, date: date).count
    expected = cache.division_count(house, date)
    return true if loaded.positive? && loaded >= expected
    return false if expected.zero?

    Searchkick.callbacks(false) { loader.call(date) }
    Division.exists?(house: house, date: date)
  rescue StandardError => e
    out.puts "#{house}/#{date}: couldn't load this day's divisions (#{e.message}), so it was skipped"
    counts[:days_not_loaded] += 1
    false
  end

  def draft(division)
    file = LocalDraftFile.new(division, model_id, root: root)
    if skip?(file)
      counts[:skipped] += 1
      return :skipped
    end

    started = Time.current
    result = summarizer(division).summarize_with(model_id)
    # The pipeline turns every error into a failed draft. A lost server isn't this division's
    # fault, so nothing is written and the run stops; the same command picks it up again.
    raise LocalModelClient::Unreachable, client.unreachable if client.unreachable

    result.error ? file.write_failed(result) : file.write(result)
    report(division, result, Time.current - started)
  end

  def skip?(file)
    return false if force

    file.drafted? || (file.failed? && !retry_failed)
  end

  def summarizer(division)
    extractor = DivisionSummaryPipeline::SemanticExtractor.new(llm_caller: client.llm_caller(division))
    DivisionSummarizer.new(division, models: { "local" => model_id }, extractor: extractor,
                                     xml_content: cache.raw(division.house, division.date),
                                     xml_fetcher: cache.fetcher)
  end

  def report(division, result, seconds)
    if result.error
      counts[:failed] += 1
      out.puts "#{slug_of(division)}: failed after #{duration(seconds)} (#{result.error.truncate(200)})"
    else
      counts[:drafted] += 1
      out.puts "#{slug_of(division)}: drafted in #{duration(seconds)}"
    end
  end

  def report_totals
    out.puts "Drafted #{counts[:drafted]}, failed #{counts[:failed]}, skipped #{counts[:skipped]} already done" \
             "#{", #{counts[:days_not_loaded]} days not loaded" if counts[:days_not_loaded].positive?}."
    out.puts "Drafts: #{shown(root.join(model_id))}/  Failed: #{shown(root.join('failed', model_id))}/"
  end

  def slug_of(division)
    "#{division.house}/#{division.date}/#{division.number}"
  end

  def duration(seconds)
    minutes, secs = seconds.round.divmod(60)
    minutes.positive? ? "#{minutes}m #{secs}s" : "#{secs}s"
  end

  def shown(path)
    Pathname(path).relative_path_from(Rails.root).to_s
  end
end

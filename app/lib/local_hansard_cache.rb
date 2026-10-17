# frozen_string_literal: true

# Sitting days' ParlParse XML for the local AI summary tasks (lib/tasks/local_llm.rake and
# LocalDraftRun), fetched once through the loader's own fetch (ARCHITECTURE.md section 5) and kept
# under tmp/hansard_xml. EarlierDebate looks back up to 70 calendar days for every division, so
# without this a snapshot takes hours; and because every run then reads the same Hansard, two
# snapshots taken with no code change between them agree.
class LocalHansardCache
  # A day with no XML is remembered so it isn't asked for again, but only for a day old enough to
  # have been published: the XML for a day that sat this week can appear later, and a marker would
  # hide it from every later run. Fourteen days is a margin chosen to cover a late Hansard, not a
  # measured publishing delay.
  RECENT_DAYS = 14

  # How many parsed days #fetcher keeps: as far back as EarlierDebate looks, for each house. A
  # parsed sitting day takes about 2.5 MB of memory (measured on days from 2026), so keeping every
  # one would hold gigabytes by the end of a run back to 2006.
  PARSED_DAYS_KEPT = DivisionSummaryPipeline::EarlierDebate::LOOKBACK_CALENDAR_DAYS * House.australian.size

  def initialize(dir: Rails.root.join("tmp/hansard_xml"))
    @dir = Pathname(dir)
    @documents = {}
    FileUtils.mkdir_p(@dir)
  end

  # The day's XML as text, or nil for a day with none (a non-sitting day is a 404).
  def raw(house, date)
    file = @dir.join("#{house}-#{date}.xml")
    missing = @dir.join("#{house}-#{date}.missing")
    return nil if missing.exist? && !recent?(date)
    return file.read if file.exist?

    document = DataLoader::Debates.fetch_xml_document(house, date.to_s)
    unless document
      FileUtils.touch(missing) unless recent?(date)
      return nil
    end

    # Written through a name of its own and renamed, so a run stopped mid-fetch leaves no part of a
    # day behind that a later run would read as the whole day.
    partial = file.sub_ext(".xml.partial")
    File.write(partial, document.to_xml)
    File.rename(partial, file)
    file.read
  end

  # How many divisions the day's XML holds. Counts "<division " so the <divisioncount> element
  # inside one isn't counted as another division.
  def division_count(house, date)
    raw(house, date).to_s.scan("<division ").size
  end

  # Whether that house voted that day: its XML holds at least one division.
  def divisions?(house, date)
    division_count(house, date).positive?
  end

  # The xml_fetcher ContextBuilder takes for earlier sitting days, parsing each day once while it's
  # in reach. A run moves through the dates in one direction, so the day read longest ago is the
  # one least likely to be asked for again, and is the one let go; a day asked for after that is
  # read again from the folder.
  def fetcher
    lambda do |house, date|
      key = "#{house}-#{date}"
      return @documents[key] if @documents.key?(key)

      text = raw(house, date)
      @documents.shift if @documents.size >= PARSED_DAYS_KEPT
      @documents[key] = text && Nokogiri::XML(text)
    end
  end

  # What a snapshot records for one division: the route, and what Stage 1 found by rule that the
  # route and the draft depend on.
  def self.snapshot_row(division, packet)
    routing = packet.routing
    {
      id: division.id, house: division.house, date: division.date.to_s, number: division.number,
      template_id: routing&.template_id, allowed: routing&.allowed_templates, forbidden: routing&.forbidden_templates,
      mode: routing&.mode.to_s, rule: routing&.rule_name, source: packet.source.to_s,
      question: packet.speaker_question.to_s[0, 160], by_reference: packet.question_by_reference?,
      states_motion: packet.question_states_motion?, mover: packet.mover&.member&.name,
      mover_found_by: packet.mover&.found_by&.to_s, motion_found: packet.motion_found?,
      limitation: packet.limitation_statement.present?, warnings: packet.context_warnings.size,
      circulated_by: packet.circulation&.by, circulator_member: packet.circulation&.member&.name
    }
  end

  private

  # Whether a day is recent enough that its Hansard could still be published.
  def recent?(date) = date >= Date.current - RECENT_DAYS
end

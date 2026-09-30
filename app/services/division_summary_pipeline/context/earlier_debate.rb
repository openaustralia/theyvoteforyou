# frozen_string_literal: true

module DivisionSummaryPipeline
  # The earlier parts of a division's own debate: the same heading earlier on the same sitting
  # day, and then on previous sitting days. ContextBuilder asks for this when the speeches in
  # front of a division do not contain the motion it decides, which happens routinely:
  #
  # - A deferred division is put without debate, often at the start of the next sitting day
  #   (House S.O. 133), so the only speech beside it is the chair saying which amendment it is.
  # - A bill's second reading debate runs over several days, and an amendment moved on the
  #   first day is voted on at the end of the last.
  # - A debate interrupted by Question Time resumes under a repeated heading, and the division
  #   after an earlier division in the same debate has only the chair's question before it.
  #
  # - A guillotine's time expires, and the chair puts the questions on a bill under a
  #   "; Limitation of Debate" heading about amendments moved in its "; Second Reading" debate.
  #
  # That last is why a debate is matched by the bills its sections are about as well as by its
  # heading. A speech found that way, under another heading, is marked :other_heading: it is a
  # different stage of the bill, so its move is not the one "just before the question", and
  # MoverFinder only credits it when the chair names its speaker as the mover.
  #
  # Only what identifies the question is kept: speeches that move something, with their whole
  # text since the mover's reasons are what the extractor quotes, and the chair's short
  # statements putting or deferring a question. The rest of a multi-day debate would be tens of
  # thousands of words about the bill in general, which buries the motion rather than finding it.
  #
  # Sitting days are fetched through the same DataLoader::Debates.fetch_xml_document the loader
  # uses (ARCHITECTURE.md, section 5); a non-sitting day is a 404, which it returns as nil.
  class EarlierDebate
    # How far back to look. A bill's second reading debate seldom stretches beyond a couple of
    # sitting fortnights; the calendar bound stops a long winter break costing dozens of fetches.
    LOOKBACK_SITTING_DAYS = 8
    LOOKBACK_CALENDAR_DAYS = 70

    # Enough for several movers' speeches, well short of the whole debate.
    MAX_CHARS = 40_000
    MAX_SPEECH_CHARS = 20_000

    # speeches: SpeechText#context_speech hashes with :date added, oldest first.
    Result = Struct.new(:speeches, :dates, keyword_init: true) do
      delegate :empty?, to: :speeches
    end

    # exhaustive: keep looking back after the first move is found, for when the extractor has
    # already reported that the narrower packet was not enough (the sitting-day retry).
    def self.collect(division_xml:, house:, date:, fetcher: nil, exhaustive: false)
      new(division_xml: division_xml, house: house, date: date, fetcher: fetcher, exhaustive: exhaustive).collect
    end

    def initialize(division_xml:, house:, date:, fetcher:, exhaustive:)
      @division_xml = division_xml
      @house = house
      @date = parse_date(date)
      @fetcher = fetcher
      @exhaustive = exhaustive
      @chars = 0
    end

    def collect
      title = division_xml.debate_title
      return Result.new(speeches: [], dates: []) if title.blank?

      collected = keep(division_xml.earlier_same_debate_speeches, date, title)
      collected = previous_days(title) + collected unless found_move?(collected) && !exhaustive

      Result.new(speeches: collected, dates: collected.pluck(:date).uniq)
    end

    private

    attr_reader :division_xml, :house, :date, :fetcher, :exhaustive

    # Newest day first, so the search stops at the most recent move; returned oldest first.
    def previous_days(title)
      return [] unless fetcher && date

      found = []
      sitting_days = 0
      bill_ids = division_xml.bill_ids
      (1..LOOKBACK_CALENDAR_DAYS).each do |offset|
        break if sitting_days >= LOOKBACK_SITTING_DAYS || @chars >= MAX_CHARS

        day = date - offset
        document = fetch(day)
        next unless document

        sitting_days += 1
        speeches = DataLoader::DebatesXml.new(document, house).speeches_under_minor_heading(title, bill_ids: bill_ids)
        found = keep(speeches, day, title) + found
        break if found_move?(found) && !exhaustive
      end
      found
    end

    # Another stage's speeches do not count against this debate's budget: ContextBuilder keeps
    # at most one of them, the move the chair named, so counting them could only crowd out this
    # debate's own.
    def keep(speech_nodes, day, title)
      heading = DataLoader::DebatesXml.normalise_heading(title)
      speech_nodes.filter_map do |node|
        speech = DataLoader::SpeechText.context_speech(node)
        next unless relevant?(speech) && @chars < MAX_CHARS

        speech = within_budget(speech)
        other_heading = DataLoader::DebatesXml.normalise_heading(DataLoader::DebatesXml.section_heading(node)&.text) != heading
        @chars += speech[:text].size unless other_heading
        speech.merge(date: day.to_s, other_heading: other_heading)
      end
    end

    # A long speech is cut to an unbroken run of whole paragraphs around its move, never inside
    # a paragraph and never with a gap in the middle, so anything quoted from it is exactly what
    # Hansard recorded, in order. The move and its terms always stay, since they are why the
    # speech was kept, and the paragraphs either side of them are where a mover explains it. A
    # quotation elsewhere in the speech is not a reason to keep it, or the run would stretch from
    # the first quotation to the move and past the budget.
    def within_budget(speech)
      paragraphs = speech[:paragraphs]
      return speech if paragraphs.sum { |paragraph| paragraph[:text].size } <= MAX_SPEECH_CHARS

      moved = paragraphs.each_index.select { |i| %i[move motion].include?(paragraphs[i][:kind]) }
      low = moved.first || 0
      high = moved.last || 0
      used = paragraphs[low..high].sum { |paragraph| paragraph[:text].size }
      loop do
        grown = [low - 1, high + 1].find { |i| i.between?(0, paragraphs.size - 1) && used + paragraphs[i][:text].size <= MAX_SPEECH_CHARS }
        break unless grown

        used += paragraphs[grown][:text].size
        grown < low ? low = grown : high = grown
      end
      kept = paragraphs[low..high]
      speech.merge(paragraphs: kept, text: kept.pluck(:text).join("\n\n"))
    end

    def relevant?(speech)
      return true if speech[:moved_text].present?

      DataLoader::DivisionXml.chair_statement_text?(speech[:text])
    end

    # A move under another of the bill's headings belongs to a different stage, so finding one
    # is no reason to stop looking for this debate's own.
    def found_move?(speeches)
      speeches.any? { |s| s[:moved_text].present? && !s[:other_heading] }
    end

    # A day that cannot be fetched is skipped rather than failing the summary: the packet is
    # still built from what was found, and the extractor can say the context was insufficient.
    def fetch(day)
      document = fetcher.call(house, day.to_s)
      document&.at(:debates) ? document : nil
    rescue StandardError => e
      Rails.logger.warn "DivisionSummaryPipeline::EarlierDebate could not fetch #{house} #{day}: #{e.message}" if defined?(Rails)
      nil
    end

    def parse_date(value)
      value.is_a?(Date) ? value : Date.parse(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end
  end
end

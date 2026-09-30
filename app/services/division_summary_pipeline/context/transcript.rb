# frozen_string_literal: true

module DivisionSummaryPipeline
  # The Hansard a context packet carries, cut into units a model can point at and code can
  # quote. It is what makes the pipeline's rule enforceable: the model selects, it never writes.
  #
  # The model is shown every unit with an ID ("[S3.4] ..."), and answers with IDs. Everything
  # published comes back out of here as the exact text Hansard recorded, retrieved by ID, so a
  # quote cannot be paraphrased, tidied, shortened or invented, and there is no question of which
  # occurrence of a repeated sentence was meant. Normalised text (TextNormaliser) is only ever
  # used to search; what is returned is always the raw text.
  #
  # Units follow the speech's own structure (DataLoader::SpeechText.paragraphs):
  #
  # - :move, the paragraph that says "I move" (or its part before an inline motion),
  # - :motion, a paragraph of the terms moved,
  # - :prose, one sentence of what a member said, and
  # - :chair, a paragraph of the chair putting this division's question.
  #
  # Only a member's own words are cut into sentences. A motion or the chair's question is quoted
  # whole, so they stay whole paragraphs. An "I move" paragraph is cut too, because members often
  # give their reasons in it before moving ("... For these reasons, I move the amendment:"): only
  # the sentence that moves is the introduction, and the rest is prose the model can quote.
  class Transcript
    # start and finish are offsets into the unit's paragraph, so consecutive units can be
    # quoted as the exact run of text they came from. move counts the moves in the speech.
    Unit = Data.define(:id, :speech_number, :index, :paragraph, :kind, :text, :start, :finish, :move)

    # date is set for speeches from an earlier sitting day; earlier marks speeches added from
    # earlier in the same debate (EarlierDebate); question marks the chair putting the question.
    Speech = Data.define(:number, :id, :speaker, :speaker_gid, :time, :date, :earlier, :question, :paragraphs,
                         :units) do
      def label
        speaker.presence || "Unnamed speaker"
      end
    end

    # A run of consecutive units from one speech, quoted exactly; paragraph breaks inside the
    # run are kept as blank lines.
    Passage = Data.define(:speech, :unit_ids, :text)

    # The exact text an anchored phrase resolved to, or why it did not (see #anchor).
    Anchor = Data.define(:text, :unit, :problem)

    # Words the sentence splitter must not end a sentence after: titles, "No. 3", "s. 53".
    ABBREVIATIONS = %w[
      mr mrs ms dr prof hon sen no nos st vs etc cf eg ie nb p pp s ss cl cll para paras art arts ch vol reg regs
      sch div subdiv approx dept govt co pty ltd inc jr sr gen lt col capt rev assoc est fig
    ].to_set.freeze
    SENTENCE_BOUNDARY = /[.!?]+["'\u2019\u201D)\]]*\s+(?=["'\u2018\u201C(\[]?[[:upper:][:digit:]])/
    TOKEN = /[[:alnum:]]+/

    attr_reader :heading, :speeches

    # speeches and earlier_speeches are DataLoader::SpeechText.context_speech hashes (earlier ones
    # with a :date), earliest first. question_speech_id is the XML id of the chair's statement
    # putting this division's question, which is always the last speech before the division.
    def self.build(heading:, speeches:, earlier_speeches: [], question_speech_id: nil)
      numbered = earlier_speeches.map { |speech| [speech, true] } + speeches.map { |speech| [speech, false] }
      new(heading: heading, speeches: numbered.each_with_index.map do |(speech, earlier), index|
        build_speech(speech, number: index + 1, earlier: earlier,
                             question: question_speech_id.present? && speech[:id] == question_speech_id)
      end)
    end

    # When no Hansard XML matched, the only source is the Division record's own stored motion
    # text: one unnamed "speech" of prose paragraphs.
    def self.from_record(heading:, text:)
      paragraphs = text.to_s.split(/\n+/).map(&:strip).reject(&:empty?).map { |line| { text: line, kind: :prose } }
      speech = { id: nil, speaker: nil, speaker_gid: nil, time: nil, paragraphs: paragraphs }
      new(heading: heading, speeches: [build_speech(speech, number: 1, earlier: false, question: false)])
    end

    def self.build_speech(speech, number:, earlier:, question:)
      paragraphs = Array(speech[:paragraphs])
      units = []
      paragraphs.each_with_index do |paragraph, paragraph_index|
        kind = question ? :chair : paragraph[:kind]
        spans = %i[prose move].include?(kind) ? sentence_spans(paragraph[:text]) : [[0, paragraph[:text].size]]
        spans.each do |start, finish|
          text = paragraph[:text][start...finish]
          unit_kind = kind == :move && !text.match?(DataLoader::SpeechText::MOVE_PATTERN) ? :prose : kind
          units << Unit.new(id: "S#{number}.#{units.size + 1}", speech_number: number, index: units.size,
                            paragraph: paragraph_index, kind: unit_kind, text: text, start: start, finish: finish,
                            move: unit_kind == :prose ? nil : paragraph[:move])
        end
      end
      Speech.new(number: number, id: speech[:id], speaker: speech[:speaker], speaker_gid: speech[:speaker_gid],
                 time: speech[:time], date: speech[:date], earlier: earlier, question: question,
                 paragraphs: paragraphs.pluck(:text), units: units)
    end

    # Offsets of each sentence in text. Conservative on purpose: a missed boundary only makes a
    # unit longer, while a false one would let a quote stop half way through a sentence.
    def self.sentence_spans(text)
      spans = []
      start = 0
      text.to_enum(:scan, SENTENCE_BOUNDARY).each do
        match = Regexp.last_match
        next if abbreviation_before?(text, start, match)

        spans << [start, match.begin(0) + match[0].rstrip.size]
        start = match.end(0)
      end
      spans << [start, text.rstrip.size] if start < text.rstrip.size
      spans
    end

    def self.abbreviation_before?(text, start, match)
      return false unless match[0].start_with?(".") && !match[0].start_with?("..")

      word = text[start...match.begin(0)][/([[:alpha:]]+)\z/, 1]
      word.present? && (ABBREVIATIONS.include?(word.downcase) || word.match?(/\A[[:upper:]]\z/))
    end

    private_class_method :build_speech, :abbreviation_before?

    def initialize(heading:, speeches:)
      @heading = heading.to_s
      @speeches = speeches
      @units = speeches.flat_map(&:units).index_by(&:id)
    end

    def units
      @units.values
    end

    # IDs are compared ignoring case and spacing, which is all a model varies in them.
    def unit(id)
      @units[id.to_s.strip.upcase]
    end

    def speech(number)
      speeches[number - 1] if number.to_i.positive?
    end

    def speech_with_id(xml_id)
      speeches.find { |speech| xml_id.present? && speech.id == xml_id }
    end

    def speech_of(unit)
      speech(unit.speech_number)
    end

    def question_speech
      speeches.find(&:question)
    end

    def earlier_dates
      speeches.select(&:earlier).filter_map(&:date).uniq
    end

    # The units of a speech's last move, of one kind (:move or :motion), in order.
    def last_move_units(speech, kind)
      moved = speech.units.select { |unit| unit.kind == kind && !unit.move.nil? }
      return [] if moved.empty?

      last = speech.units.reject { |unit| unit.move.nil? }.last.move
      moved.select { |unit| unit.move == last }
    end

    # The exact text of the given units, as runs of consecutive units in document order. Unknown
    # IDs are skipped; callers check IDs with #unit first when that matters.
    def passages(ids)
      chosen = ids.filter_map { |id| unit(id) }.uniq.sort_by { |unit| [unit.speech_number, unit.index] }
      runs = chosen.slice_when { |a, b| a.speech_number != b.speech_number || b.index != a.index + 1 }
      runs.map do |run|
        speech = speech_of(run.first)
        Passage.new(speech: speech, unit_ids: run.map(&:id), text: run_text(speech, run))
      end
    end

    # Finds phrase inside one unit and returns Hansard's own text for it. The phrase is only a
    # locator: it is matched word for word ignoring case and punctuation, and what comes back is
    # the unit's raw text from the first matched word to the last. A phrase found at several
    # places is refused unless every place reads exactly the same.
    def anchor(unit_id, phrase)
      found = unit(unit_id)
      return Anchor.new(text: nil, unit: nil, problem: :no_such_unit) unless found

      wanted = TextNormaliser::ENTITY_DECODER.decode(phrase.to_s).scan(TOKEN).map(&:downcase)
      return Anchor.new(text: nil, unit: found, problem: :empty) if wanted.empty?

      texts = anchored_texts(found.text, wanted)
      return Anchor.new(text: nil, unit: found, problem: :not_found) if texts.empty?
      return Anchor.new(text: nil, unit: found, problem: :ambiguous) if texts.size > 1

      Anchor.new(text: texts.first, unit: found, problem: nil)
    end

    # The transcript as the model sees it: each speech under a header, each unit on its own line
    # with its ID, a blank line between paragraphs, and the kind shown for everything that is
    # not a member's own words.
    def prompt_text
      lines = ["DEBATE: #{TextNormaliser.clean_text(heading)}", ""]
      earlier, current = speeches.partition(&:earlier)
      unless earlier.empty?
        lines << "EARLIER IN THIS DEBATE (only the speeches that moved something or put a question, " \
                 "from #{earlier_dates.join(', ')}):"
        lines << ""
        earlier.each { |speech| lines.concat(speech_lines(speech)) }
        lines << "THE SPEECHES BEFORE THIS DIVISION:"
        lines << ""
      end
      current.each { |speech| lines.concat(speech_lines(speech)) }
      lines.join("\n")
    end

    # The heading and the first words spoken, for the router's check of which stage a debate is
    # at ("in committee", "consideration in detail").
    def opening_text(limit = 1000)
      [TextNormaliser.clean_text(heading), *speeches.flat_map(&:paragraphs)].join("\n")[0, limit]
    end

    private

    def speech_lines(speech)
      stamp = [speech.date, speech.time.presence].compact.join(" ")
      header = "--- S#{speech.number}: #{speech.label}"
      header += ", #{stamp}" if stamp.present?
      header += " (the chair putting this division's question)" if speech.question
      lines = ["#{header} ---"]
      speech.units.each_with_index do |unit, position|
        lines << "" if position.positive? && unit.paragraph != speech.units[position - 1].paragraph
        tag = unit.kind == :prose ? unit.id : "#{unit.id} #{unit.kind}"
        lines << "[#{tag}] #{unit.text}"
      end
      lines << ""
    end

    def run_text(speech, run)
      run.chunk_while { |a, b| a.paragraph == b.paragraph }.map do |piece|
        speech.paragraphs[piece.first.paragraph][piece.first.start...piece.last.finish]
      end.join("\n\n")
    end

    def anchored_texts(text, wanted)
      have = text.to_enum(:scan, TOKEN).map { [Regexp.last_match[0].downcase, Regexp.last_match.begin(0), Regexp.last_match.end(0)] }
      starts = (0..(have.size - wanted.size)).select { |i| have[i, wanted.size].map(&:first) == wanted }
      starts.map { |i| balanced(text, have[i][1], have[i + wanted.size - 1][2]) }.uniq
    end

    # A name that ends inside brackets ("the Example (Special Account) Bill" cut after
    # "Account") keeps its closing bracket, and one that starts inside them keeps the opening.
    def balanced(text, from, to)
      to += 1 while text[from...to].count("(") > text[from...to].count(")") && text[to] == ")"
      from -= 1 while text[from...to].count(")") > text[from...to].count("(") && from.positive? && text[from - 1] == "("
      text[from...to]
    end
  end
end

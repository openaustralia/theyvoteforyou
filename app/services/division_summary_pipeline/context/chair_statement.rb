# frozen_string_literal: true

module DivisionSummaryPipeline
  # The chair's statement putting a division's question, read by rule (ARCHITECTURE.md, Data
  # classification: Type 2 text). The router, the prompt, MoverFinder and the Question Put section
  # all read it, and before this each read it its own way: the whole statement, amendments and all,
  # decided the route, and a long one was taken for a member's speech (KI-35, KI-41). So it is
  # read once, here.
  #
  # A statement can put several questions in turn, each decided on the voices closed by "Question
  # agreed to." or "Question negatived.", and the division follows the last one put. At Senate
  # 18 August 2026 #16 the chair put the government's amendments, recorded them agreed to, and then
  # put the "stand as printed" question the division decided: 45,679 characters in one statement,
  # most of it amendments Hansard incorporates in italic after each question.
  #
  # paragraphs: the statement's DataLoader::SpeechText.paragraphs. The chair's own words are :prose
  # there, what Hansard set in italic, such as the amendments being put, :quotation, and Hansard's
  # records of questions decided ("Question agreed to.") :record.
  class ChairStatement
    # The chair putting a question, in the forms found in the chair's statements before divisions
    # in House and Senate Hansard from May to September 2026: "The question is that" (253 times),
    # "now is" (26), "The first question is" (4), "The immediate question is" (1) and "The next
    # question is" (1). "Second" and "third" follow "first". Members also say "the real question
    # is", which this does not match.
    QUESTION = /\bthe\s+(?:(?:first|second|third|next|immediate)\s+)?question\s+(?:now\s+)?is\s+that\b/i

    # Hansard recording a question decided on the voices, which closes it: a later question in the
    # same statement is a different one. The forms found in those statements: "Question agreed to.",
    # "Question negatived.", "Original question agreed to." and "Bills read a second time.".
    DECIDED = /\A(?:(?:original\s+)?question\s+(?:agreed\s+to|negatived|resolved\s+in\s+the\s+(?:affirmative|negative))|
                 bills?\s+read\s+a\s+(?:first|second|third)\s+time)\b/xi

    # A question on amendments, whose terms the statement may print after it.
    ON_AMENDMENTS = /\bamendments?\b|\bsheets?\b|\bstand\s+as\s+printed\b/i

    # The headings Hansard sets in plain type among the amendments it prints: "SHEET 3829",
    # "Australian Greens circulated amendments—". Anything longer is the chair speaking again.
    TERMS_HEADING_MAXIMUM = 100

    # Who circulated the amendments the chair puts, in the chair's words, as found in the Senate's
    # statements for May to September 2026: "circulated by the Australian Greens" (13 times), "One
    # Nation" (7), "Senator David Pocock" (6), "the opposition" (4), "the United Australia Party",
    # "the government", "Jacqui Lambie Network and Senator David Pocock". The House names a member
    # by electorate.
    CIRCULATED_BY = /\bcirculated\s+by\s+(
      the\s+(?:opposition|government)\b |
      the\s+(?:honourable\s+)?member\s+for\s+[A-Z][\w'’-]*(?:\s+[A-Z][\w'’-]*)* |
      (?:the\s+)?[A-Z][\w'’-]*(?:\s+(?:and\s+)?[A-Z][\w'’-]*)*
    )/x

    # Hansard's heading over them when the chair does not say: "Australian Greens' circulated
    # amendments—", "One Nation 's circulated amendment", "Senator David Pocock's circulated
    # amendments", "Government' s circulated amendments—" (the stray spaces are Hansard's).
    CIRCULATED_HEADING = /\A(?:the\s+)?(\S.*?)\s*(?:['’]\s*s?)?\s+circulated\s+a\s?mendments?\b/i

    # Names that read with "the" in front, which the heading leaves off: "circulated by the
    # Government", "the Australian Greens", "the United Australia Party", "the Jacqui Lambie Network".
    TAKES_ARTICLE = /\b(?:government|opposition|coalition|greens|party|network)\z/i

    # A divided question (Senate S.O. 84(3): "The President may order a complicated question to be
    # divided"), in the chair's words putting what is left: "the substantive motion, minus 2(a) and
    # (b), be agreed to", or "except paragraph 3". Only the Senate's forms have been seen (Senate
    # 18 August 2026 #2); the House, where a member may move that a question be divided (House S.O.
    # 119), had none in its Hansard from May to September 2026, so none is assumed.
    DIVIDED = /\b(?:minus|except)\s+((?:paragraphs?\s+)?\d.*?),?\s+be\s+agreed\s+to\b/i

    # The parts left out of a divided question, in the chair's words ("2(a) and (b)"), or nil.
    def self.divided_parts(text)
      text.to_s[DIVIDED, 1]&.strip
    end

    def initialize(paragraphs)
      @paragraphs = Array(paragraphs)
    end

    # The sentence putting the question the division decided: the last question sentence in the
    # chair's own words. Nil when the statement puts none in these words, as older files, which
    # record only the motion, do.
    def question
      index = question_index
      return nil unless index

      text = paragraphs[index][:text]
      spans = Transcript.sentence_spans(text).select { |start, finish| text[start...finish].match?(QUESTION) }
      start, finish = spans.last
      start ? text[start...finish] : text
    end

    # The paragraphs in which the chair puts that question: the chair's own words from the last
    # question decided before it up to the one that puts it. What the Question Put section quotes,
    # and where the chair names who moved or circulated what is being put. Everything the chair
    # said, when no question sentence was found.
    def putting_indices
      plain = plain_indices
      index = question_index
      return plain unless index

      decided = paragraphs.each_index.select { |i| i < index && decided?(i) }.max || -1
      plain.select { |i| i > decided && i <= index }
    end

    def putting_text
      putting_indices.map { |i| paragraphs[i][:text] }.join("\n\n")
    end

    # The terms of the amendments the question puts, when the statement prints them: the
    # paragraphs straight after the question, up to the next question or the record of one decided.
    # Under a limitation of debate nobody moves circulated amendments, so this is the only place
    # Hansard records them, and they were once left for the model to find: one model listed about
    # 140 paragraph IDs as the motion, and the retry that followed read 104,000 tokens
    # (KI-44). Taken only when the question itself refers to amendments,
    # because in the House, when time expires, opposition amendments that were never put are
    # sometimes printed only "so that the intentions of the Opposition are recorded" (House Guide
    # p. 75).
    def terms_indices
      index = question_index
      return [] unless index && question.match?(ON_AMENDMENTS)

      run = ((index + 1)...paragraphs.size).take_while { |i| terms_paragraph?(i) }
      last_italic = run.rindex { |i| paragraphs[i][:kind] == :quotation }
      last_italic ? run[0..last_italic] : []
    end

    # Who circulated the amendments the question puts, as Hansard names them: from the chair's own
    # words putting the question, or failing that from Hansard's heading over the terms.
    def circulated_by
      said = putting_text[CIRCULATED_BY, 1]
      return said.strip if said

      heading = terms_indices.lazy.filter_map { |i| paragraphs[i][:text].strip[CIRCULATED_HEADING, 1] }.first
      return nil if heading.blank?

      heading.match?(TAKES_ARTICLE) ? "the #{heading}" : heading
    end

    # Whether the question put more than one amendment: anything but a question on "the
    # amendment" alone, since "stand as printed" questions decide several items to be opposed as
    # often as one.
    def plural?
      text = question.to_s
      !(text.match?(/\bamendment\b/i) && !text.match?(/\bamendments\b/i))
    end

    private

    attr_reader :paragraphs

    def plain_indices
      paragraphs.each_index.select { |i| paragraphs[i][:kind] == :prose }
    end

    def question_index
      return @question_index if defined?(@question_index)

      @question_index = plain_indices.reverse.find { |i| paragraphs[i][:text].match?(QUESTION) }
    end

    def decided?(index)
      paragraphs[index][:text].strip.match?(DECIDED)
    end

    def terms_paragraph?(index)
      paragraph = paragraphs[index]
      return true if paragraph[:kind] == :quotation

      text = paragraph[:text].strip
      paragraph[:kind] == :prose && text.size <= TERMS_HEADING_MAXIMUM && !text.match?(DECIDED) && !text.match?(QUESTION)
    end
  end
end

# frozen_string_literal: true

module DivisionSummaryPipeline
  # How deeply each line of a quoted motion sits in its outline, so EvidenceSections can quote
  # "(i)" one level further in than the "(a)" it belongs to (">>" rather than ">") (KI-66).
  #
  # Hansard's XML gives every paragraph of a motion as a flat <p>, so the labels are all that is
  # left to show how the paragraphs nest. A label style ("(1)", "(a)", "(i)", "(A)", "(I)") is one
  # level further in than the style open before it the first time it appears, and a paragraph
  # going back to a style already open goes back to that style's level, so an outline can start
  # at any style. A paragraph without a label stays at the outer level, as every paragraph did
  # before this, and a blank line between two levels is quoted at the shallower one.
  #
  # "(i)", "(v)" and "(x)" are letters as well as Roman numerals. Each is a numeral when it
  # continues an open list of numerals, and a letter when it continues an open list of letters,
  # except that "(i)" straight after "(h)" starts a list of numerals under "(h)" when "(ii)"
  # follows it.
  #
  # Only the depth is worked out here. The words stay Hansard's, untouched.
  class QuoteOutline
    LABEL = /\A\(([[:alnum:]]{1,5})\)/
    ROMAN_UNITS = ["", "i", "ii", "iii", "iv", "v", "vi", "vii", "viii", "ix"].freeze
    # "i" to "xxxix", in order.
    ROMAN_NUMERALS = (1..39).map { |n| ("x" * (n / 10)) + ROMAN_UNITS[n % 10] }.freeze

    # lines: the motion's lines, blank ones separating paragraphs. Returns one depth per line,
    # 1 for the outer level.
    def self.depths(lines)
      new(lines).depths
    end

    def initialize(lines)
      @lines = lines.map(&:strip)
      @open = []
      @last_label = {}
    end

    def depths
      levels = Array.new(lines.size)
      paragraphs.each_with_index do |rows, index|
        level = level_for(label(rows.first), label(paragraphs[index + 1]&.first))
        rows.each { |row| levels[row] = level }
      end
      levels.each_index.map { |row| levels[row] || between(levels, row) }
    end

    private

    attr_reader :lines

    # Each paragraph as the indices of its lines.
    def paragraphs
      @paragraphs ||= lines.each_index.reject { |row| lines[row].empty? }.slice_when { |a, b| b != a + 1 }.to_a
    end

    def label(row)
      row && lines[row][LABEL, 1]
    end

    def level_for(label, next_label)
      return 1 unless label

      style = style_of(label, next_label)
      if (position = @open.index(style))
        @open.slice!((position + 1)..).each { |closed| @last_label.delete(closed) }
      else
        @open << style
      end
      @last_label[style] = label
      @open.size
    end

    def style_of(label, next_label)
      return :number if label.match?(/\A\d/)

      letter, numeral = label.match?(/\A[[:upper:]]/) ? %i[capital capital_numeral] : %i[letter numeral]
      return letter unless ROMAN_NUMERALS.include?(label.downcase)
      return numeral if label.length > 1 || continues?(numeral, label)
      return letter if continues?(letter, label) && !first_of_numerals?(label, next_label)

      label.casecmp?("i") ? numeral : letter
    end

    # "(i)" followed by "(ii)" starts a list of numerals, even straight after "(h)".
    def first_of_numerals?(label, next_label)
      label.casecmp?("i") && next_label.to_s.casecmp?("ii")
    end

    def continues?(style, label)
      previous = @last_label[style]
      return false unless previous

      if %i[numeral capital_numeral].include?(style)
        ROMAN_NUMERALS.index(previous.downcase) + 1 == ROMAN_NUMERALS.index(label.downcase)
      else
        previous.downcase.succ == label.downcase
      end
    end

    def between(levels, row)
      before = levels[0...row].reverse.compact.first
      after = levels[(row + 1)..].compact.first
      [before, after].compact.min || 1
    end
  end
end

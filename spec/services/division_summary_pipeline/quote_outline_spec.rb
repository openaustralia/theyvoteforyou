# frozen_string_literal: true

require "spec_helper"

# KI-66: Hansard's XML gives a motion's paragraphs flat, so the labels are all that shows how
# they nest. The rendered quote is in template_compiler_spec.rb, "an outlined motion".
describe DivisionSummaryPipeline::QuoteOutline do
  # Paragraphs separated by blank lines, as a motion's text arrives.
  def depths(*paragraphs)
    described_class.depths(paragraphs.flat_map { |paragraph| [paragraph, ""] }[0...-1])
  end

  it "puts a list of numerals one level in from the lettered paragraph above it, and the next letter back out" do
    expect(depths("(a) notes:", "(i) the first matter,", "(ii) the second matter; and", "(b) calls on the Government to:"))
      .to eq([1, 1, 2, 2, 2, 1, 1])
  end

  it "quotes a blank line between two levels at the shallower one" do
    expect(depths("(a) notes:", "(i) the first matter,")).to eq([1, 1, 2])
  end

  it "leaves a list with one style of label at the outer level" do
    expect(depths("That the Senate:", "(1) notes the report;", "(2) calls on the Government to respond."))
      .to eq([1, 1, 1, 1, 1])
  end

  it "starts the outline at whichever style comes first" do
    expect(depths("(1) That the Senate:", "(a) notes:", "(i) the first matter;", "(b) calls on the Government;",
                  "(2) That the report be printed."))
      .to eq([1, 1, 2, 2, 3, 2, 2, 1, 1])
  end

  it "starts the letters again under the next number" do
    expect(depths("(1) That:", "(a) one;", "(b) two;", "(2) That:", "(a) three.")).to eq([1, 1, 2, 2, 2, 1, 1, 1, 2])
  end

  it "leaves a paragraph without a label at the outer level" do
    expect(depths("(a) notes:", "(i) the first matter,", "and that the bill be withdrawn.")).to eq([1, 1, 2, 1, 1])
  end

  it "gives every line of a paragraph the paragraph's depth" do
    expect(described_class.depths(["(a) notes:", "", "(i) the first matter,", "continued", "", "(b) calls."]))
      .to eq([1, 1, 2, 2, 1, 1])
  end

  describe "labels that are letters as well as numerals" do
    it "takes (i) straight after (h) as the next letter" do
      expect(depths("(g) seven;", "(h) eight;", "(i) nine; and", "(j) ten.")).to eq([1, 1, 1, 1, 1, 1, 1])
    end

    it "takes (i) after (h) as the first numeral of a list under (h) when (ii) follows it" do
      expect(depths("(h) eight:", "(i) one,", "(ii) two;", "(j) ten.")).to eq([1, 1, 2, 2, 2, 1, 1])
    end

    it "takes (v) as a numeral after (iv) and as a letter after (u)" do
      expect(depths("(a) notes:", "(iv) four,", "(v) five;", "(b) calls.")).to eq([1, 1, 2, 2, 2, 1, 1])
      expect(depths("(t) twenty;", "(u) twenty-one;", "(v) twenty-two.")).to eq([1, 1, 1, 1, 1])
    end

    it "takes (x) as a numeral after (ix) and as a letter after (w)" do
      expect(depths("(a) notes:", "(ix) nine,", "(x) ten;")).to eq([1, 1, 2, 2, 2])
      expect(depths("(w) twenty-three;", "(x) twenty-four.")).to eq([1, 1, 1])
    end

    it "does the same for capitals" do
      expect(depths("(G) seven;", "(H) eight;", "(I) nine.")).to eq([1, 1, 1, 1, 1])
      expect(depths("(a) notes:", "(A) the first matter,", "(B) the second matter:", "(I) in part,", "(II) in full;"))
        .to eq([1, 1, 2, 2, 2, 2, 3, 3, 3])
    end
  end
end

# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

# The shapes of the chair's statements before divisions in Senate Hansard for August 2026, with
# invented members, bills and amendments.
describe DivisionSummaryPipeline::ChairStatement do
  def statement(inner_xml)
    node = Nokogiri::XML("<speech id=\"s9\" speakername=\"Casey Whitlow\">#{inner_xml}</speech>").root
    described_class.new(DataLoader::SpeechText.paragraphs(node))
  end

  describe "#question" do
    # KNOWN_ISSUES.md KI-35, from Senate 20 August 2026 #17.
    it "is the question sentence, not the chair's lead-in before it" do
      chair = statement("<p>As that matter was resolved in the affirmative, the consequential amendment on sheet 9005 " \
                        "will not be put. The question now is that the remaining stages of the bill be agreed to and " \
                        "the bill be now passed.</p>")

      expect(chair.question).to eq("The question now is that the remaining stages of the bill be agreed to and the " \
                                   "bill be now passed.")
    end

    # As at Senate 18 August 2026 #4, where words in the amendments once settled the route.
    it "leaves out the amendments Hansard prints in italic after the question" do
      chair = statement(<<~XML)
        <p>I will now deal with the amendments circulated by the Example Party. The question is that the amendments on sheets 9101 and 9102 be agreed to.</p>
        <p class="italic">SHEET 9101</p>
        <p class="italic">Omit all words after "That", substitute "the Senate rejects the bill and calls for a select committee to be established".</p>
      XML

      expect(chair.question).to eq("The question is that the amendments on sheets 9101 and 9102 be agreed to.")
    end

    # As at Senate 18 August 2026 #16: the first question was decided on the voices before the
    # division, which decided the second.
    it "is the last question the statement puts, however it is numbered" do
      chair = statement(<<~XML)
        <p>The question now is that amendments (1) to (4) on sheet XY101 be agreed to.</p>
        <p class="italic">(1) Clause 2, page 2 (table item 3), omit the item.</p>
        <p>Question agreed to.</p>
        <p>I will now deal with the remaining amendments circulated by the Example Party. The first question is that part 3 of schedule 1 stand as printed.</p>
        <p class="italic">(2) Schedule 1, Part 3, page 12 (line 1) to page 14 (line 9), to be opposed.</p>
      XML

      expect(chair.question).to eq("The first question is that part 3 of schedule 1 stand as printed.")
    end

    it "is nil when the chair puts no question in these words" do
      expect(statement("<p>That the question be now put.</p>").question).to be_nil
    end

    it "does not take a member's \"the real question is\" for the chair putting one" do
      expect(statement("<p>The real question is that this bill hurts renters.</p>").question).to be_nil
    end
  end

  describe "#circulated_by" do
    it "is who the chair says circulated the amendments, in the chair's words" do
      chair = statement("<p>I will now deal with the amendments circulated by the Example Party. The question is that " \
                        "the amendments on sheet 9101 be agreed to.</p><p class=\"italic\">(1) Clause 2, omit the clause.</p>")
      senator = statement("<p>The question is that the amendment on sheet 9102, circulated by Senator Jo Marlowe, be agreed " \
                          "to.</p>")

      expect(chair.circulated_by).to eq("the Example Party")
      expect(senator.circulated_by).to eq("Senator Jo Marlowe")
    end

    # The stray spaces are Hansard's, as in "Government' s circulated amendments—".
    it "is taken from Hansard's heading over the amendments when the chair does not say" do
      party = statement("<p>The question is that the amendments on sheet XY102 be agreed to.</p>" \
                        "<p class=\"italic\">Example Greens ' circulated amendments—</p><p class=\"italic\">(1) Clause 2, omit the clause.</p>")
      government = statement("<p>The question is that the amendments on sheet XY103 be agreed to.</p>" \
                             "<p class=\"italic\">Government' s circulated amendments—</p><p class=\"italic\">(1) Clause 3, omit the clause.</p>")
      senator = statement("<p>The question is that the amendment on sheet 9104 be agreed to.</p>" \
                          "<p>Senator Jo Marlowe's circulated amendment—</p><p class=\"italic\">(1) Clause 4, omit the clause.</p>")

      expect(party.circulated_by).to eq("the Example Greens")
      expect(government.circulated_by).to eq("the Government")
      expect(senator.circulated_by).to eq("Senator Jo Marlowe")
    end

    it "is nil when Hansard does not say" do
      expect(statement("<p>The question is that the amendment moved by Senator Marlowe be agreed to.</p>").circulated_by).to be_nil
    end
  end

  # KI-53, from Senate 18 August 2026 #2.
  describe ".divided_parts" do
    it "is what a divided question left out, in the chair's words" do
      expect(described_class.divided_parts("The question is that the substantive motion, minus 2(a) and (b), be agreed to."))
        .to eq("2(a) and (b)")
      expect(described_class.divided_parts("The question is that the motion, except paragraph 3, be agreed to."))
        .to eq("paragraph 3")
    end

    it "is nil for a question put whole" do
      expect(described_class.divided_parts("The question is that the motion be agreed to.")).to be_nil
    end
  end

  describe "#putting_text" do
    it "is the chair's own words putting the question the division decided, after any question decided before it" do
      chair = statement(<<~XML)
        <p>I remind senators that there will be one-minute bells. The question is that these bills be now read a second time.</p>
        <p>Question agreed to.</p>
        <p>Original question agreed to.</p>
        <p>Bills read a second time.</p>
        <p>I will now deal with the amendment circulated by the Example Party. The question is that the amendment on sheet 9103 be agreed to.</p>
        <p class="italic">(1) Page 16 (after line 4), insert: 12A Protections for tenants</p>
      XML

      expect(chair.putting_text).to eq("I will now deal with the amendment circulated by the Example Party. The question " \
                                       "is that the amendment on sheet 9103 be agreed to.")
    end

    it "is everything the chair said when no question sentence is found" do
      expect(statement("<p>That the question be now put.</p>").putting_text).to eq("That the question be now put.")
    end
  end
end

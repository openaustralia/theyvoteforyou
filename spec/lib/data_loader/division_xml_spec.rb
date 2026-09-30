# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

# The methods DataLoader::DivisionXml exposes for the AI division summary pipeline. The loader's
# own behaviour is covered against real Hansard fixtures in debates_xml_spec.rb.
describe DataLoader::DivisionXml do
  def divisions(body)
    DataLoader::DebatesXml.new(Nokogiri::XML("<debates>#{body}</debates>"), "senate").divisions
  end

  let(:heading) { "<major-heading id=\"h1\">BILLS</major-heading><minor-heading id=\"h2\">Fair Pricing Bill 2026; Second Reading</minor-heading>" }

  describe "#preceded_by_division?" do
    it "is true when the division follows another with nothing between them" do
      second = divisions("#{heading}<division divnumber=\"1\" id=\"d1\"/><division divnumber=\"2\" id=\"d2\"/>").last

      expect(second.preceded_by_division?).to be(true)
    end

    # Each amendment in a Senate second reading debate is moved and put in turn under one
    # heading. The move sits right in front of its own division, so this is not a run of
    # questions without debate, which is what the flag once wrongly reported.
    it "is false when a speech sits between this division and the earlier one" do
      second = divisions(<<~XML).last
        #{heading}
        <division divnumber="1" id="d1"/>
        <speech id="s1" speakername="Morgan Treloar"><p>I move the second reading amendment on sheet 9001:</p></speech>
        <division divnumber="2" id="d2"/>
      XML

      expect(second.preceded_by_division?).to be(false)
    end

    # The chair puts each question of a run in words of its own, and current Hansard records
    # them as a speech by the named member in the chair, so they do not break the run.
    it "is true when only the chair putting the next question sits between the divisions" do
      second = divisions(<<~XML).last
        #{heading}
        <division divnumber="1" id="d1"/>
        <speech id="s1" speakerid="uk.org.publicwhip/lord/900001" speakername="Casey Whitlow"><p>The question now is that the amendment moved by Senator Treloar be agreed to.</p></speech>
        <division divnumber="2" id="d2"/>
      XML

      expect(second.preceded_by_division?).to be(true)
    end
  end

  describe "#run_statements" do
    let(:deferred_run) do
      divisions(<<~XML)
        #{heading}
        <speech id="s1" speakername="Morgan Treloar"><p>That is why the amendment should be supported.</p></speech>
        <speech id="s2" speakername="Casey Whitlow"><p>In accordance with standing order 133, I shall now proceed to put the question on the amendment moved by the member for Exampleton, on which a division was called for and deferred.</p><p>The question is that the amendment be agreed to.</p></speech>
        <division divnumber="1" id="d1"/>
        <speech id="s3" speakername="Casey Whitlow"><p>The question now is that the amendment moved by the member for Fairview be agreed to.</p></speech>
        <division divnumber="2" id="d2"/>
        <speech id="s4" speakername="Casey Whitlow"><p>The question now is that the bill be now read a second time.</p></speech>
        <division divnumber="3" id="d3"/>
      XML
    end

    # Only the first question of a deferred run says it was deferred.
    it "reaches back across the run to what the chair said before its first question" do
      statements = deferred_run.last.run_statements

      expect(statements.size).to eq(3)
      expect(statements.first).to start_with("In accordance with standing order 133")
      expect(statements.last).to eq("The question now is that the bill be now read a second time.")
    end

    it "stops at the debate in front of the run" do
      expect(deferred_run.first.run_statements.join).not_to include("should be supported")
    end
  end

  describe "#debate_title" do
    it "is the raw minor heading, so the same debate can be found on other days" do
      division = divisions("#{heading}<division divnumber=\"1\" id=\"d1\"/>").first

      expect(division.debate_title).to eq("Fair Pricing Bill 2026; Second Reading")
    end
  end

  describe "#earlier_same_debate_speeches" do
    it "finds speeches before an earlier division and under an earlier appearance of the heading" do
      division = divisions(<<~XML).last
        #{heading}
        <speech id="s1" speakername="Robin Carrow"><p>I move the amendment circulated in my name.</p></speech>
        <minor-heading id="h3">Questions without Notice</minor-heading>
        <speech id="s2" speakername="Sam Okafor"><p>An unrelated question.</p></speech>
        <minor-heading id="h4">Fair Pricing Bill 2026; Second Reading</minor-heading>
        <speech id="s3" speakername="Jess Harlow"><p>Debate resumed.</p></speech>
        <division divnumber="1" id="d1"/>
        <speech id="s4" speakername="Casey Whitlow"><p>The question now is that the bill be read a second time.</p></speech>
        <division divnumber="2" id="d2"/>
      XML

      speakers = division.earlier_same_debate_speeches.map { |speech| speech.attr(:speakername) }

      expect(speakers).to eq(["Robin Carrow", "Jess Harlow"])
    end

    # Under a guillotine the questions are put under "; Limitation of Debate", about amendments
    # moved in the "; Second Reading" debate. The bills listed under each heading tie them together.
    it "finds the same bill's debate under another heading, and not another bill's" do
      fair_pricing = "<bills><bill id=\"r9001\" url=\"x\">Fair Pricing Bill 2026</bill></bills>"
      division = divisions(<<~XML).last
        #{heading}
        #{fair_pricing}
        <speech id="s1" speakername="Robin Carrow"><p>I move the second reading amendment on sheet 9001.</p></speech>
        <minor-heading id="h3">Clean Rivers Bill 2026; Second Reading</minor-heading>
        <bills><bill id="r9002" url="x">Clean Rivers Bill 2026</bill></bills>
        <speech id="s2" speakername="Sam Okafor"><p>I move the second reading amendment on sheet 9002.</p></speech>
        <minor-heading id="h4">Fair Pricing Bill 2026; Limitation of Debate</minor-heading>
        #{fair_pricing}
        <speech id="s3" speakername="Casey Whitlow"><p>The question is that the amendment moved by Senator Carrow be agreed to.</p></speech>
        <division divnumber="1" id="d1">#{fair_pricing}</division>
      XML

      speakers = division.earlier_same_debate_speeches.map { |speech| speech.attr(:speakername) }

      expect(speakers).to eq(["Robin Carrow"])
    end
  end

  describe "#limitation_of_debate_statement" do
    let(:chair) { "speakerid=\"uk.org.publicwhip/lord/900001\" speakername=\"Casey Whitlow\"" }
    let(:expiry) do
      "<speech id=\"s1\" #{chair}><p>Pursuant to order agreed on 18 August 2026, the time allotted for " \
        "consideration of these bills has expired. The question is that the amendment on sheet 9001 be agreed to.</p></speech>"
    end

    # As on 20 August 2026, when one order's time expired and 24 divisions on 12 bills followed.
    it "reaches back across other bills' sections to the chair saying the time has expired" do
      last = divisions(<<~XML).last
        <minor-heading id="h2">Fair Pricing Bill 2026; Limitation of Debate</minor-heading>
        #{expiry}
        <division divnumber="1" id="d1"/>
        <minor-heading id="h3">Clean Rivers Bill 2026; Limitation of Debate</minor-heading>
        <speech id="s2" speakerid="uk.org.publicwhip/lord/900003" speakername="Morgan Treloar"><p>I table a supplementary explanatory memorandum relating to the government amendments to be moved to this bill.</p></speech>
        <speech id="s3" #{chair}><p>The question now is that the remaining stages of the bill be agreed to and the bill be now passed.</p></speech>
        <division divnumber="2" id="d2"/>
      XML

      expect(last.limitation_of_debate_statement.attr(:id)).to eq("s1")
    end

    # As on 18 August 2026, when only the second reading's time expired, under that stage's own
    # heading, and the chair read out every amendment circulated as she put it.
    it "finds a statement that cites the order under another heading, past the chair's long statements" do
      circulated = "<p>(1) Schedule 1, item 1, page 3 (lines 4 and 5), omit the item.</p>" * 30
      last = divisions(<<~XML).last
        #{heading}
        <speech id="s1" #{chair}><p>Pursuant to order, the time allotted for the second reading of this bill has expired. The question is that the amendments on sheet 9001 be agreed to.</p></speech>
        <division divnumber="1" id="d1"/>
        <speech id="s2" #{chair}><p>I will now deal with the amendments circulated by Senator Treloar. The question is that the amendments on sheet 9002 be agreed to.</p>#{circulated}</speech>
        <division divnumber="2" id="d2"/>
      XML

      expect(last.limitation_of_debate_statement.attr(:id)).to eq("s1")
    end

    it "finds the statement when the chair goes straight on to read out the first amendment" do
      circulated = "<p>(1) Schedule 1, item 1, page 3 (lines 4 and 5), omit the item.</p>" * 30
      division = divisions(<<~XML).last
        <minor-heading id="h2">Fair Pricing Bill 2026; Limitation of Debate</minor-heading>
        <speech id="s1" #{chair}><p>Pursuant to order, the time allotted for the remaining stages of this bill has expired. The question is that the amendments on sheet 9001 be agreed to.</p>#{circulated}</speech>
        <division divnumber="1" id="d1"/>
      XML

      expect(division.limitation_of_debate_statement.attr(:id)).to eq("s1")
    end

    # A senator asking by leave to have their vote recorded stops it too, which only leaves the
    # guillotine unmentioned in the draft.
    it "is nil when anyone but the chair speaks between the statement and the division" do
      last = divisions(<<~XML).last
        #{heading}
        <speech id="s1" #{chair}><p>Pursuant to order, the time allotted for the second reading of this bill has expired. The question is that the amendments on sheet 9001 be agreed to.</p></speech>
        <division divnumber="1" id="d1"/>
        <speech id="s2" speakerid="uk.org.publicwhip/lord/900003" speakername="Morgan Treloar"><p>By leave, I ask that my name be recorded as opposing the amendment.</p></speech>
        <speech id="s3" #{chair}><p>The question now is that the bill be now read a second time.</p></speech>
        <division divnumber="2" id="d2"/>
      XML

      expect(last.limitation_of_debate_statement).to be_nil
    end

    it "is nil once the bill has moved on to a stage debated under its own heading" do
      last = divisions(<<~XML).last
        <minor-heading id="h2">Fair Pricing Bill 2026; Limitation of Debate</minor-heading>
        #{expiry}
        <division divnumber="1" id="d1"/>
        <minor-heading id="h3">Fair Pricing Bill 2026; In Committee</minor-heading>
        <speech id="s2" #{chair}><p>The question is that the amendment moved by Senator Treloar be agreed to.</p></speech>
        <division divnumber="2" id="d2"/>
      XML

      expect(last.limitation_of_debate_statement).to be_nil
    end

    # The standing orders time some debates themselves. Their chair cites the standing order, not
    # an order of the Senate, and no bill's questions are being put without debate.
    it "is nil for a debate the standing orders time" do
      division = divisions(<<~XML).last
        <minor-heading id="h2">Cost of Living; Matter of Urgency</minor-heading>
        <speech id="s1" #{chair}><p>Pursuant to standing order 75, the time allotted for the discussion has expired. The question is that the motion moved by Senator Treloar be agreed to.</p></speech>
        <division divnumber="1" id="d1"/>
      XML

      expect(division.limitation_of_debate_statement).to be_nil
    end
  end

  describe "#question_speech" do
    it "is the chair putting the question, named as current Hansard names the chair" do
      division = divisions(<<~XML).first
        #{heading}
        <speech id="s1" speakername="Morgan Treloar"><p>I move the second reading amendment on sheet 9001:</p></speech>
        <speech id="s2" speakername="Casey Whitlow"><p>The question is that the amendment be agreed to.</p></speech>
        <division divnumber="1" id="d1"/>
      XML

      expect(division.question_speech.attr(:id)).to eq("s2")
    end

    it "is the unnamed speech older files use for the chair" do
      division = divisions(<<~XML).first
        #{heading}
        <speech id="s1" nospeaker="true"><p pwmotiontext="moved">That the question be now put.</p></speech>
        <division divnumber="1" id="d1"/>
      XML

      expect(division.question_speech.attr(:id)).to eq("s1")
    end

    # As at Senate 18 August 2026 #4, where eight circulated amendments made the chair's statement
    # 8,550 characters and the draft said the question was never recorded.
    it "is the chair's statement however many amendments Hansard prints in it" do
      amendments = "<p class=\"italic\">Omit all words after \"That\", substitute \"the Senate rejects the bill\".</p>" * 60
      division = divisions(<<~XML).first
        #{heading}
        <speech id="s1" speakername="Casey Whitlow"><p>I will now deal with the amendments circulated by the Example Party. The question is that the amendments on sheets 9001 to 9008 be agreed to.</p>#{amendments}</speech>
        <division divnumber="1" id="d1"/>
      XML

      expect(division.question_speech.attr(:id)).to eq("s1")
    end

    it "still is not a member's long speech that happens to say \"the question is\"" do
      argument = "<p>The question is whether renters can afford this, and I say they cannot.</p>" * 20
      division = divisions(<<~XML).first
        #{heading}
        <speech id="s1" speakername="Morgan Treloar">#{argument}</speech>
        <division divnumber="1" id="d1"/>
      XML

      expect(division.question_speech).to be_nil
    end

    # Then the question itself was not recorded, and a member's speech is not it.
    it "is nil when the last speech is a member speaking" do
      division = divisions(<<~XML).first
        #{heading}
        <speech id="s1" speakername="Morgan Treloar"><p>I will be voting against this bill because it is unfair to students.</p></speech>
        <division divnumber="1" id="d1"/>
      XML

      expect(division.question_speech).to be_nil
    end
  end

  describe "#operative_question" do
    it "keeps the paragraph breaks of the chair's statement when there is no pwmotiontext" do
      division = divisions(<<~XML).first
        #{heading}
        <speech id="s1" speakername="Casey Whitlow"><p>The question is that the amendment be agreed to.</p><p>Question negatived.</p></speech>
        <division divnumber="1" id="d1"/>
      XML

      expect(division.operative_question).to eq("The question is that the amendment be agreed to.\n\nQuestion negatived.")
    end

    # The italic paragraphs are the amendments being put, and a sheet that mentioned a select
    # committee once settled a vote on second reading amendments as establishing one.
    it "leaves out the amendments Hansard prints in italic in the chair's statement" do
      division = divisions(<<~XML).first
        #{heading}
        <speech id="s1" speakername="Casey Whitlow"><p>The question is that the amendments on sheet 9001 be agreed to.</p><p class="italic">Omit all words after "That", substitute "a select committee be established".</p></speech>
        <division divnumber="1" id="d1"/>
      XML

      expect(division.operative_question).to eq("The question is that the amendments on sheet 9001 be agreed to.")
    end

    # With no chair's statement the member's move is all there is to route on, terms and all.
    it "keeps the italic terms when the last speech is a member moving something" do
      division = divisions(<<~XML).first
        #{heading}
        <speech id="s1" speakername="Morgan Treloar"><p>I move:</p><p class="italic">That the debate be adjourned.</p></speech>
        <division divnumber="1" id="d1"/>
      XML

      expect(division.operative_question).to eq("I move:\n\nThat the debate be adjourned.")
    end
  end

  describe "#context_speeches" do
    it "returns each speech with its paragraphs separated and the motion it moved" do
      division = divisions(<<~XML).first
        #{heading}
        <speech id="s1" speakername="Morgan Treloar" time="13:27"><p>I move:</p><p class="italic">At the end of the motion, add ", but the Senate:</p><p class="italic">(a) notes the cost".</p></speech>
        <division divnumber="1" id="d1"/>
      XML

      speech = division.context_speeches.first
      expect(speech[:text]).to eq("I move:\n\nAt the end of the motion, add \", but the Senate:\n\n(a) notes the cost\".")
      expect(speech[:moved_text]).to eq("At the end of the motion, add \", but the Senate:\n\n(a) notes the cost\".")
    end

    # The motion a long debate decides was moved at its start, beyond the speeches this tier
    # keeps, and a closure moved near the end must not be all that is left of it.
    it "keeps the latest move from before the tail of a long debate in front of it" do
      argument = (1..30).map { |n| "<speech id=\"a#{n}\" speakername=\"Jess Harlow\"><p>Argument number #{n}.</p></speech>" }.join
      division = divisions(<<~XML).first
        #{heading}
        <speech id="m1" speakername="Robin Carrow"><p>I move:</p><p class="italic">That so much of the standing orders be suspended as would prevent the senator moving a motion.</p></speech>
        #{argument}
        <speech id="c1" speakername="Sam Okafor"><p>I move:</p><p class="italic">That the question be now put.</p></speech>
        <division divnumber="1" id="d1"/>
      XML

      speeches = division.context_speeches

      expect(speeches.size).to eq(26)
      expect(speeches.first[:speaker]).to eq("Robin Carrow")
      expect(speeches.last[:moved_text]).to eq("That the question be now put.")
    end

    it "adds nothing when the whole debate is within the tier" do
      division = divisions(<<~XML).first
        #{heading}
        <speech id="m1" speakername="Robin Carrow"><p>I move:</p><p class="italic">That the debate be adjourned.</p></speech>
        <speech id="a1" speakername="Jess Harlow"><p>We oppose adjourning it.</p></speech>
        <division divnumber="1" id="d1"/>
      XML

      expect(division.context_speeches.pluck(:speaker)).to eq(["Robin Carrow", "Jess Harlow"])
    end
  end
end

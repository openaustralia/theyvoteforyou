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

  describe "#operative_question" do
    it "keeps the paragraph breaks of the chair's statement when there is no pwmotiontext" do
      division = divisions(<<~XML).first
        #{heading}
        <speech id="s1" speakername="Casey Whitlow"><p>The question is that the amendment be agreed to.</p><p>Question negatived.</p></speech>
        <division divnumber="1" id="d1"/>
      XML

      expect(division.operative_question).to eq("The question is that the amendment be agreed to.\n\nQuestion negatived.")
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

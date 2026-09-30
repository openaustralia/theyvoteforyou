# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

describe DataLoader::SpeechText do
  def speech(inner_xml)
    Nokogiri::XML("<speech speakername=\"Morgan Treloar\" speakerid=\"uk.org.publicwhip/lord/900001\" " \
                  "time=\"13:27\">#{inner_xml}</speech>").root
  end

  describe ".paragraph_text" do
    # Nokogiri's #text runs sibling paragraphs together ("the Senate:(a) notes"), and a model
    # quoting it with a normal space then failed the verbatim check.
    it "keeps a blank line between paragraphs" do
      node = speech("<p>At the end of the motion, add \", but the Senate:</p><p class=\"italic\">(a) notes the delay;</p>")

      expect(described_class.paragraph_text(node)).to eq("At the end of the motion, add \", but the Senate:\n\n(a) notes the delay;")
    end

    it "separates the clauses of older files, which nest them in definition lists" do
      node = speech("<p>I move:</p><dl><dt>(a)</dt><dd>notes the report;</dd><dt>(b)</dt><dd>calls on the Government to act.</dd></dl>")

      expect(described_class.paragraph_text(node)).to eq("I move:\n\n(a)\n\nnotes the report;\n\n(b)\n\ncalls on the Government to act.")
    end

    it "collapses the spacing inside a paragraph" do
      expect(described_class.paragraph_text(speech("<p>Leave\n   granted.</p>"))).to eq("Leave granted.")
    end

    it "drops the stray full stop Hansard puts before some hyphenated words" do
      node = speech("<p>The scheme is\u00A0\u00A0\u00A0.anti-competitive and unfair.</p>")

      expect(described_class.paragraph_text(node)).to eq("The scheme is anti-competitive and unfair.")
    end

    it "drops what is left of the speaker's name at the start of a speech" do
      expect(described_class.paragraph_text(speech("<p>():  I rise to speak to the bill.</p>"))).to eq("I rise to speak to the bill.")
    end
  end

  describe ".moved_text" do
    it "reads the italic paragraphs after \"I move\", which is how current Hansard marks a motion" do
      node = speech(<<~XML)
        <p>I move the second reading amendment on sheet 9001:</p>
        <p class="italic">At the end of the motion, add ", but the Senate:</p>
        <p class="italic">(a) notes the cost of the scheme".</p>
        <p>This amendment is about fairness.</p>
      XML

      expect(described_class.moved_text(node)).to eq("At the end of the motion, add \", but the Senate:\n\n(a) notes the cost of the scheme\".")
    end

    it "reads pwmotiontext paragraphs, which older files use instead" do
      node = speech("<p>I move:</p><p pwmotiontext=\"moved\">That the debate be adjourned.</p>")

      expect(described_class.moved_text(node)).to eq("That the debate be adjourned.")
    end

    it "reads a motion given in the same sentence" do
      expect(described_class.moved_text(speech("<p>I move: That the question be now put.</p>"))).to eq("That the question be now put.")
    end

    it "does not take an incorporated speech that follows as part of the motion" do
      node = speech(<<~XML)
        <p>I move:</p>
        <p class="italic">That this bill be now read a second time.</p>
        <p>I seek leave to have the second reading speech incorporated in Hansard.</p>
        <p class="italic">The speech read as follows.</p>
      XML

      expect(described_class.moved_text(node)).to eq("That this bill be now read a second time.")
    end

    it "reads the Senate's longer forms of \"I move\"" do
      on_behalf = speech("<p>I, and also on behalf of Senator Okafor, move:</p><p class=\"italic\">That the Senate notes the report.</p>")
      presenting = speech("<p>I present the bill and move:</p><p class=\"italic\">That this bill may proceed without formalities.</p>")

      expect(described_class.moved_text(on_behalf)).to eq("That the Senate notes the report.")
      expect(described_class.moved_text(presenting)).to eq("That this bill may proceed without formalities.")
    end

    it "reads a move made while presenting a report or tabling a document" do
      report = speech("<p>I present the report of the Example References Committee, together with accompanying " \
                      "documents and move:</p><p class=\"italic\">That the Senate take note of the report.</p>")
      tabling = speech("<p>I table a revised explanatory memorandum relating to the bill and move:</p>" \
                       "<p class=\"italic\">That this bill be now read a second time.</p>")

      expect(described_class.moved_text(report)).to eq("That the Senate take note of the report.")
      expect(described_class.moved_text(tabling)).to eq("That this bill be now read a second time.")
    end

    it "is nil for a speech that moves nothing, including \"I move on to\"" do
      expect(described_class.moved_text(speech("<p>I move on to my second point about the bill.</p>"))).to be_nil
      expect(described_class.moved_text(speech("<p>The question is that the motion be agreed to.</p>"))).to be_nil
    end
  end

  describe ".paragraphs" do
    # The pipeline quotes a member's explanation and the motion separately, so it has to know
    # which words are which rather than guessing from their position.
    it "labels the move, the motion and the member's own words" do
      node = speech(<<~XML)
        <p>This amendment is about fairness.</p>
        <p>I move the second reading amendment on sheet 9001:</p>
        <p class="italic">At the end of the motion, add ", but the Senate:</p>
        <p class="italic">(a) notes the cost of the scheme".</p>
        <p>Students deserve better.</p>
      XML

      expect(described_class.paragraphs(node)).to eq(
        [
          { text: "This amendment is about fairness.", kind: :prose },
          { text: "I move the second reading amendment on sheet 9001:", kind: :move, move: 0 },
          { text: "At the end of the motion, add \", but the Senate:", kind: :motion, move: 0 },
          { text: "(a) notes the cost of the scheme\".", kind: :motion, move: 0 },
          { text: "Students deserve better.", kind: :prose }
        ]
      )
    end

    it "splits an inline motion from the words that introduce it, keeping both exactly" do
      expect(described_class.paragraphs(speech("<p>I move: That the question be now put.</p>"))).to eq(
        [{ text: "I move:", kind: :move, move: 0 }, { text: "That the question be now put.", kind: :motion, move: 0 }]
      )
    end

    it "labels every move in a speech, so an earlier motion is never read as prose" do
      node = speech(<<~XML)
        <p>I move:</p>
        <p class="italic">That the debate be adjourned.</p>
        <p>If that fails, I move:</p>
        <p class="italic">That the question be now put.</p>
      XML

      kinds = described_class.paragraphs(node).map { |block| [block[:kind], block[:move]] }
      expect(kinds).to eq([[:move, 0], [:motion, 0], [:move, 1], [:motion, 1]])
      expect(described_class.moved_text(node)).to eq("That the question be now put.")
    end

    it "treats \"I move on to\" as prose" do
      expect(described_class.paragraphs(speech("<p>I move on to my second point.</p>")))
        .to eq([{ text: "I move on to my second point.", kind: :prose }])
    end

    # Hansard sets what a member quotes or reads out in italic. Before KI-38 it read as their own
    # words, and a draft printed a minister's old statement as the quoting senator's explanation.
    it "labels an italic paragraph that follows no move as a quotation, and the member's aside between two as prose" do
      node = speech(<<~XML)
        <p>The minister, in 2019, said:</p>
        <p class="italic">This scheme is without precedent&#x2014;</p>
        <p>I am quoting her here&#x2014;</p>
        <p class="italic">in the history of the portfolio.</p>
        <p>That was her view then.</p>
        <p>I move:</p>
        <p class="italic">That the Senate notes the minister's statement.</p>
      XML

      expect(described_class.paragraphs(node).pluck(:kind))
        .to eq(%i[prose quotation prose quotation prose move motion])
      expect(described_class.moved_text(node)).to eq("That the Senate notes the minister's statement.")
    end

    describe "a speech incorporated by leave" do
      # The Senate's usual shape: the minister moves, seeks leave, and the House speech follows,
      # opening with the House's own "I move". Read as a move it made the whole speech the motion (KI-39).
      let(:node) do
        speech(<<~XML)
          <p>I table an explanatory memorandum relating to the bill and move:</p>
          <p class="italic">That this bill be now read a second time.</p>
          <p>I seek leave to have the second reading speech incorporated in <i>Hansard</i>.</p>
          <p>Leave granted.</p>
          <p class="italic"> <i>The speech read as follows&#x2014;</i></p>
          <p class="italic">I move that this Bill be now read a second time.</p>
          <p class="italic">This Bill makes the Example Levy fairer.</p>
          <p>Debate adjourned.</p>
        XML
      end

      it "keeps it as the member's own words, the notice before it apart, and finds only the real move" do
        expect(described_class.paragraphs(node).map { |block| [block[:kind], block[:move]] })
          .to eq([[:move, 0], [:motion, 0], [:prose, nil], [:prose, nil], [:quotation, nil],
                  [:prose, nil], [:prose, nil], [:prose, nil]])
        expect(described_class.moved_text(node)).to eq("That this bill be now read a second time.")
      end

      it "recognises the notice however Hansard wrote it" do
        notices = [
          "<p class=\"italic\">The speeches read as follows&#x2014;</p>",
          "<p> <i>The speech</i> <i>es</i> <i> read as follows&#x2014;</i></p>",
          "<p>The incorporated speech read as follows&#x2014;</p>",
          "<p>() (): The incorporated speech read as follows&#x2014;</p>"
        ]

        notices.each do |notice|
          kinds = described_class.paragraphs(speech("#{notice}<p class=\"italic\">The levy is fair.</p>")).pluck(:kind)
          expect(kinds).to eq(%i[quotation prose]), notice
        end
      end

      it "does not treat a report or document introduced the same way as the member's words" do
        node = speech("<p class=\"italic\"> <i>The report read as follows&#x2014;</i></p><p class=\"italic\">The committee met twice.</p>")

        expect(described_class.paragraphs(node).pluck(:kind)).to eq(%i[quotation quotation])
      end

      # Senate files set lists inside an incorporated speech in plain <ul> elements, and a plain
      # paragraph is where the member speaks again.
      it "ends at the first plain paragraph, so a list stays inside it and a later move is still found" do
        node = speech(<<~XML)
          <p class="italic">The speech read as follows&#x2014;</p>
          <p class="italic">The bill amends these Acts:</p>
          <ul><li>Example Levy Act 2001</li></ul>
          <p class="italic">It should pass.</p>
          <p>I move:</p>
          <p class="italic">That the debate be adjourned.</p>
        XML

        expect(described_class.paragraphs(node).pluck(:kind)).to eq(%i[quotation prose prose prose move motion])
        expect(described_class.moved_text(node)).to eq("That the debate be adjourned.")
      end
    end
  end

  describe ".context_speech" do
    it "carries the Hansard speaker id so the mover can be looked up as a member" do
      result = described_class.context_speech(speech("<p>I move: That the question be now put.</p>"))

      expect(result).to include(speaker: "Morgan Treloar", speaker_gid: "uk.org.publicwhip/lord/900001", time: "13:27",
                                moved_text: "That the question be now put.")
    end
  end
end

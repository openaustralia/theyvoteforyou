require "spec_helper"

describe Division, type: :model do
  describe "#formatted_motion_text" do
    it do
      division = Division.new(motion: "A bill [No. 2] and votes")
      expect(division.formatted_motion_text).to eq("<p>A bill [No. 2] and votes</p>\n")
    end
    it do
      division = Division.new(motion: "This remark[1] deserves a footnote", markdown: false)
      expect(division.formatted_motion_text).to eq("<p>This remark<sup class=\"sup-1\"><a class=\"sup\" href='#footnote-1' onclick=\"ClickSup(1); return false;\">[1]</a></sup> deserves a footnote</p>\n")
    end

    describe "update old site links" do
      context "publicwhip-test" do
        subject(:division) { Division.new(motion: "<a href=\"http://publicwhip-test.openaustraliafoundation.org.au\">Foobar</a>") }

        it do
          division.markdown = false
          expect(division.formatted_motion_text).to eq("<p><a href=\"https://theyvoteforyou.org.au\">Foobar</a></p>\n")
        end

        it do
          division.markdown = true
          expect(division.formatted_motion_text).to eq("<p><a href=\"https://theyvoteforyou.org.au\">Foobar</a></p>\n")
        end
      end

      context "publicwhip-rails" do
        subject(:division) { Division.new(motion: "<a href=\"http://publicwhip-rails.openaustraliafoundation.org.au\">Foobar</a>") }

        it do
          division.markdown = false
          expect(division.formatted_motion_text).to eq("<p><a href=\"https://theyvoteforyou.org.au\">Foobar</a></p>\n")
        end

        it do
          division.markdown = true
          expect(division.formatted_motion_text).to eq("<p><a href=\"https://theyvoteforyou.org.au\">Foobar</a></p>\n")
        end
      end
    end
  end

  describe "#passed?" do
    subject(:division) { Division.new }

    it "should not be passed when there's a draw" do
      allow(division).to receive(:aye_majority) { 0 }
      expect(division.passed?).to be(false)
    end
  end

  describe "footnotes" do
    let(:text) {
      <<-EOF
A paragraph.

A paragraph with a footnote.[1]

''Background to the bill''

Something else with a footnote.[2]

Hmm.. yes.[3] And then some

Yup [4].

''References''
* [1] A footnote for sure [https://www.openaustralia.org.au/senate/?gid=2014-09-02.4.3 here].
* [2] Yup. No kidding. [https://www.openaustralia.org.au/debates/?id=2014-09-01.34.2 here]. It's a link.
* [3] Read more
* [4] Read more about superannuation
      EOF
    }

    it ".footnotes" do
      expect(Division.footnotes(text)).to eq ({
        "1" => "A footnote for sure [https://www.openaustralia.org.au/senate/?gid=2014-09-02.4.3 here].",
        "2" => "Yup. No kidding. [https://www.openaustralia.org.au/debates/?id=2014-09-01.34.2 here]. It's a link.",
        "3" => "Read more",
        "4" => "Read more about superannuation"
      })
    end

    it ".remove_footnotes" do
      expect(Division.remove_footnotes(text)).to eq <<-EOF
A paragraph.

A paragraph with a footnote.[1]

''Background to the bill''

Something else with a footnote.[2]

Hmm.. yes.[3] And then some

Yup [4].

    EOF
    end

    it ".inline_footnotes" do
      expect(Division.inline_footnotes(text)).to eq <<-EOF
A paragraph.

A paragraph with a footnote.(A footnote for sure [https://www.openaustralia.org.au/senate/?gid=2014-09-02.4.3 here].)

''Background to the bill''

Something else with a footnote.(Yup. No kidding. [https://www.openaustralia.org.au/debates/?id=2014-09-01.34.2 here]. It's a link.)

Hmm.. yes.(Read more) And then some

Yup (Read more about superannuation).

      EOF
    end
  end

  describe "::next_month" do
    it "returns the next month" do
      expect(Division.next_month("2014-12")).to eq("2015-01-01")
    end
  end
end

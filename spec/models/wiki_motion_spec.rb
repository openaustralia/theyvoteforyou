require 'spec_helper'

describe WikiMotion, :type => :model do
  let(:text) {
    <<-EOF
A paragraph.

A paragraph with a footnote.[1]

''Background to the bill''

Something else with a footnote.[2]

Hmm.. yes.[3] And then some

Yup [4].

''References''
* [1] A footnote for sure [http://www.openaustralia.org/senate/?gid=2014-09-02.4.3 here].
* [2] Yup. No kidding. [http://www.openaustralia.org/debates/?id=2014-09-01.34.2 here]. It's a link.
* [3] Read more
* [4] Read more about superannuation
    EOF
  }

  it ".footnotes" do
    expect(WikiMotion.footnotes(text)).to eq ({
      "1" => "A footnote for sure [http://www.openaustralia.org/senate/?gid=2014-09-02.4.3 here].",
      "2" => "Yup. No kidding. [http://www.openaustralia.org/debates/?id=2014-09-01.34.2 here]. It's a link.",
      "3" => "Read more",
      "4" => "Read more about superannuation"
    })
  end

  it ".remove_footnotes" do
    expect(WikiMotion.remove_footnotes(text)).to eq <<-EOF
A paragraph.

A paragraph with a footnote.[1]

''Background to the bill''

Something else with a footnote.[2]

Hmm.. yes.[3] And then some

Yup [4].

''References''
    EOF
  end

  it ".inline_footnotes" do
    expect(WikiMotion.inline_footnotes(text)).to eq <<-EOF
A paragraph.

A paragraph with a footnote.(A footnote for sure [http://www.openaustralia.org/senate/?gid=2014-09-02.4.3 here].)

''Background to the bill''

Something else with a footnote.(Yup. No kidding. [http://www.openaustralia.org/debates/?id=2014-09-01.34.2 here]. It's a link.)

Hmm.. yes.(Read more) And then some

Yup (Read more about superannuation).

''References''
    EOF
  end
end

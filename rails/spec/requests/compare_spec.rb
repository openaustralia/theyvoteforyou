require 'spec_helper'
require 'net/http'
# Compare results of rendering pages via rails and via the old php app

def tidy(text)
  File.open("temp.html", "w") {|f| f.write(text) }
  # Requires HTML Tidy (http://tidy.sourceforge.net/) version 14 June 2007 or later
  # Can install on OS X with "brew install tidy"
  # Note the version installed with OS X by default is a version that's too old
  system("/usr/local/bin/tidy --sort-attributes alpha -q -m temp.html")
  r = File.read("temp.html")
  # Make sure that comments of the form <!-- comment --> are followed by a new line
  File.delete("temp.html")
  r.gsub("--><", "-->\n<")
end

# Convert into a form where html can be reliably diff'd
def normalise_html(text)
  tidy(text)
end

def compare_html(old_html, new_html)
  n = normalise_html(new_html)
  o = normalise_html(old_html)

  FileUtils.rm_f("old.html")
  FileUtils.rm_f("new.html")
  if n != o
    # Write it out to a file
    File.open("old.html", "w") {|f| f.write(o.to_s)}
    File.open("new.html", "w") {|f| f.write(n.to_s)}
    raise "Don't match. Writing to file old.html and new.html"
  end
end

describe "Comparing" do
  def compare(path)
    get path
    text = Net::HTTP.get('localhost', path)
    text.force_encoding(Encoding::UTF_8)
    compare_html(text, response.body)
  end

  it "/" do
    compare("/")
  end

  it "/" do
    compare("/mps.php")
  end
end

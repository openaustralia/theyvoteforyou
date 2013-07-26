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
  #Nokogiri::XML::Document.parse(text, nil, "UTF-8", &:noblanks).to_xhtml(indent: 2)
end

describe "Comparing" do
  it "/" do
    get "/"
    text = Net::HTTP.get('localhost', '/')
    text.force_encoding(Encoding::UTF_8)
    n = normalise_html(response.body)
    o = normalise_html(text)

    if n != o
      # Write it out to a file
      File.open("old.html", "w") {|f| f.write(o.to_s)}
      File.open("new.html", "w") {|f| f.write(n.to_s)}
      raise "Don't match. Writing to file old.html and new.html"
    end
  end

  it "/" do
    get "/mps.php"
    # Convert all tabs to spaces so that tidy gives more reliable results
    text = Net::HTTP.get('localhost', '/mps.php').gsub("\t", "  ")
    text.force_encoding(Encoding::UTF_8)
    n = normalise_html(response.body)
    o = normalise_html(text)

    if n != o
      # Write it out to a file
      File.open("old.html", "w") {|f| f.write(o.to_s)}
      File.open("new.html", "w") {|f| f.write(n.to_s)}
      raise "Don't match. Writing to file old.html and new.html"
    end
  end
end

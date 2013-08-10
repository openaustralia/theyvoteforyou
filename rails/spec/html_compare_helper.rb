# Originally from https://raw.github.com/openaustralia/planningalerts-app/d5b1ead73f220b7e56ef402bb833f51b2e5144d3/spec/html_compare_helper.rb

require 'open-uri'
require 'net/http'

module HTMLCompareHelper
  def compare(path)
    get path
    text = Net::HTTP.get((ENV['PHP_SERVER'] || 'localhost'), path)
    text.force_encoding(Encoding::UTF_8)
    compare_html(text, response.body, path)
  end

  private

  def compare_html(old_html, new_html, path)
    n = normalise_html(new_html)
    o = normalise_html(old_html)

    if n != o
      # Write it out to a file
      output("old.html", o, path)
      output("new.html", n, path)
      exec("diff old.html new.html")
      raise "Don't match. Writing to file old.html and new.html"
    end
  end

  def output(file, text, comment)
    File.open(file, "w") do |f|
      f.write("<!-- " + comment + " -->\n")
      f.write(text.to_s)
    end
  end

  # Convert into a form where html can be reliably diff'd
  def normalise_html(text)
    tidy(text)
  end

  def tidy(text)
    File.open("temp.html", "w") {|f| f.write(text) }
    # Requires HTML Tidy (http://tidy.sourceforge.net/) version 14 June 2007 or later
    # Note the version installed with OS X by default is a version that's too old
    # Install on OS X with "brew install tidy" and replace your system "tidy" with
    # a symlink to the homebrew installed one
    system("tidy --show-warnings no --sort-attributes alpha -utf8 -q -m temp.html")
    r = File.read("temp.html")
    # Make sure that comments of the form <!-- comment --> are followed by a new line
    File.delete("temp.html")
    r.gsub("--><", "-->\n<")
  end
end

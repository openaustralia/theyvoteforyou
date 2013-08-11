# Originally from https://raw.github.com/openaustralia/planningalerts-app/d5b1ead73f220b7e56ef402bb833f51b2e5144d3/spec/html_compare_helper.rb

require 'open-uri'
require 'net/http'

module HTMLCompareHelper
  def compare(path)
    get path
    text = Net::HTTP.get(php_server, path)
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
      exec("#{diff_path} old.html new.html")
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
    # Install on OS X with "brew install tidy"
    system("#{tidy_path} --show-warnings no --sort-attributes alpha -utf8 -q -m temp.html")
    r = File.read("temp.html")
    # Make sure that comments of the form <!-- comment --> are followed by a new line
    File.delete("temp.html")
    r.gsub("--><", "-->\n<")
  end

  def php_server
    ENV['PHP_SERVER'] || 'localhost'
  end

  def tidy_path
    # On OS X use tidy installed with Homebrew in preference to any other
    # It would normally be first in the path but we can't depend on that being the case here
    if File.exists? "/usr/local/bin/tidy"
      "/usr/local/bin/tidy"
    else
      "tidy"
    end
  end

  def diff_path
    # On OS X use opendiff in preference to any other diff. Fallback to regular diff somewhere
    # in the path so that this works on Linux as well.
    if File.exists? "/usr/bin/opendiff"
      "/usr/bin/opendiff"
    else
      "diff"
    end
  end
end

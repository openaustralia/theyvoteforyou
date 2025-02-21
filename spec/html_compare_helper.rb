# frozen_string_literal: true

# Originally from https://raw.github.com/openaustralia/planningalerts-app/d5b1ead73f220b7e56ef402bb833f51b2e5144d3/spec/html_compare_helper.rb

require "open-uri"
require "net/http"
require "uri"

module HTMLCompareHelper
  include Warden::Test::Helpers
  Warden.test_mode!

  def compare_static(path, form_params: false, format: "html")
    if form_params
      post(path, params: form_params)
      # Follow multiple redirects
      get(response.headers["Location"]) while response.headers["Location"]
    else
      get(path)
    end

    text = File.read("spec/fixtures/static_pages#{path.gsub '?', '__'}.#{format}")

    compare_text(text, response.body, path, format)
  end

  private

  def compare_text(old_text, new_text, path, format = "html")
    n = normalise(new_text, format)
    o = normalise(old_text, format)
    return if n == o

    # Switch overwrite to false if you don't want changes to be automatically written out
    overwrite = true

    raise "Don't match" unless overwrite

    # Write it out to a file
    File.write("spec/fixtures/static_pages#{path.gsub '?', '__'}.#{format}", new_text)
    puts new_text
    raise "Don't match. Writing over file in spec/fixtures/static_pages. Do a git diff."
  end

  def output(file, text, comment)
    File.open(file, "w") do |f|
      f.write("<!-- #{comment} -->\n")
      f.write(text.to_s)
    end
  end

  def normalise(text, format)
    format == "xml" ? normalise_xml(text) : normalise_html(text)
  end

  # Convert into a form where html can be reliably diff'd
  def normalise_html(text)
    tidy(text)
  end

  def normalise_xml(text)
    tidy(text, :xml)
  end

  def tidy(text, format = :html)
    File.write("temp", text)
    # Requires HTML Tidy (http://tidy.sourceforge.net/) version 14 June 2007 or later
    # Note the version installed with OS X by default is a version that's too old
    # Install on OS X with "brew install tidy"
    command = "#{tidy_path}#{' -xml' if format == :xml} --show-warnings no --sort-attributes alpha --drop-empty-elements no -utf8 -q -m temp"
    system(command)

    r = File.read("temp")
    # Make sure that comments of the form <!-- comment --> are followed by a new line
    File.delete("temp")
    r.gsub("--><", "-->\n<")
  end

  def tidy_path
    # On OS X use tidy installed with Homebrew in preference to any other
    # It would normally be first in the path but we can't depend on that being the case here
    if File.exist? "/usr/local/bin/tidy"
      "/usr/local/bin/tidy"
    else
      "tidy"
    end
  end
end

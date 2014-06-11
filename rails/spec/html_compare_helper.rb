# Originally from https://raw.github.com/openaustralia/planningalerts-app/d5b1ead73f220b7e56ef402bb833f51b2e5144d3/spec/html_compare_helper.rb

require 'open-uri'
require 'net/http'
require 'uri'

module HTMLCompareHelper
  def compare(path, signed_in = false)
    if signed_in
      ApplicationController.any_instance.stub current_user: User.find(1)
      connection = Net::HTTP.new php_server
      text = connection.get(path, {'Cookie' => 'user_name=henare; id_hash=0e53908d0c6a97f05b39c5dfb64a197a'}).body
    else
      text = Net::HTTP.get(php_server, path)
    end

    get path
    text.force_encoding(Encoding::UTF_8)
    compare_text(text, response.body, path)
  end

  def compare_post(path, signed_in, form_params)
    agent = Mechanize.new
    headers = {}
    if signed_in
      ApplicationController.any_instance.stub current_user: User.find(1)
      headers['Cookie'] = 'user_name=henare; id_hash=0e53908d0c6a97f05b39c5dfb64a197a'
    end
    post path, form_params
    # Follow redirect
    get response.headers['Location'] if response.headers['Location']

    text = agent.post("http://#{php_server}#{path}", form_params, headers).body
    text.force_encoding(Encoding::UTF_8)

    compare_text(text, response.body, path)
  end

  def compare_post_static(path, signed_in, form_params)
    ApplicationController.any_instance.stub current_user: User.find(1) if signed_in

    post path, form_params
    text = File.read("spec/fixtures/static_pages/#{path}.html")
    compare_text(text, response.body, path)
  end

  private

  def compare_text(old_text, new_text, path)
    format = URI.parse(path).path[-3..-1] == 'xml' ? 'xml' : 'html'

    if format == 'xml'
      n = normalise_xml(new_text)
      o = normalise_xml(old_text)
    else
      n = normalise_html(new_text)
      o = normalise_html(old_text)
    end

    if n != o
      # Write it out to a file
      output("old.#{format}", o, path)
      output("new.#{format}", n, path)
      exec("#{diff_path} old.#{format} new.#{format}")
      raise "Don't match. Writing to file old.#{format} and new.#{format}"
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

  def normalise_xml(text)
    tidy(text, :xml)
  end

  def tidy(text, format = :html)
    File.open("temp", "w") {|f| f.write(text) }
    # Requires HTML Tidy (http://tidy.sourceforge.net/) version 14 June 2007 or later
    # Note the version installed with OS X by default is a version that's too old
    # Install on OS X with "brew install tidy"
    command = "#{tidy_path}#{' -xml' if format == :xml} --show-warnings no --sort-attributes alpha -utf8 -q -m temp"
    if system(command).nil? || $?.exitstatus > 1 #tidy is stupid and returns 1 on warning, 2 on failure.
      raise "tidy command failed '#{command}'"
    end

    r = File.read("temp")
    # Make sure that comments of the form <!-- comment --> are followed by a new line
    File.delete("temp")
    r.gsub("--><", "-->\n<")
  end

  def php_server
    ENV['PHP_SERVER'] || 'dev.publicwhip.org.au'
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

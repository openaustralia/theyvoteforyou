# Originally from https://raw.github.com/openaustralia/planningalerts-app/d5b1ead73f220b7e56ef402bb833f51b2e5144d3/spec/html_compare_helper.rb

require 'open-uri'
require 'net/http'
require 'uri'
require 'factory_girl'

module HTMLCompareHelper
  include Warden::Test::Helpers
  Warden.test_mode!

  def compare(path, signed_in = false)
    raise 'Function deprecated. All comparisons should use compare_static now.'
    if signed_in
      login_as(create_user, scope: :user)

      connection = Net::HTTP.new php_server
      text = connection.get(path, {'Cookie' => 'user_name=henare; id_hash=eafc72bcea49e39de90363fcde8f749f'}).body
    else
      text = Net::HTTP.get(php_server, path)
    end

    get path
    text.force_encoding(Encoding::UTF_8)
    compare_text(text, response.body, path)
  end

  def compare_post(path, signed_in, form_params)
    raise 'Function deprecated. All comparisons should use compare_static now.'
    agent = Mechanize.new
    headers = {}
    if signed_in
      login_as(create_user, scope: :user)
      headers['Cookie'] = 'user_name=henare; id_hash=eafc72bcea49e39de90363fcde8f749f'
    end

    post path, form_params
    # Follow redirect
    get response.headers['Location'] if response.headers['Location']

    text = agent.post("http://#{php_server}#{path}", form_params, headers).body
    text.force_encoding(Encoding::UTF_8)

    compare_text(text, response.body, path)
  end

  def compare_static(path, signed_in = false, form_params = false, suffix = "", method = :post)
    login_as(create_user, scope: :user) if signed_in

    if form_params
      if method == :post
        post(path, form_params)
      elsif method == :put
        put(path, form_params)
      else
        raise "Unexpected value for method"
      end
    else
      get(path)
    end
    # Follow multiple redirects
    while response.headers['Location']
      get response.headers['Location']
    end

    text = File.read("spec/fixtures/static_pages#{path}#{suffix}.html")

    compare_text(text, response.body, path, suffix)
  end

  private

  def compare_text(old_text, new_text, path, suffix = "")
    format = 'xml'

    n = normalise(new_text, format)
    o = normalise(old_text, format)

    if n != o
      # Write it out to a file
      File.open("spec/fixtures/static_pages#{path}#{suffix}.html", "w") do |f|
        f.write new_text
      end
      raise "Don't match. Writing over file in spec/fixtures/static_pages. Do a git diff."
    end
  end

  def output(file, text, comment)
    File.open(file, "w") do |f|
      f.write("<!-- " + comment + " -->\n")
      f.write(text.to_s)
    end
  end

  def normalise(text, format)
    format == 'xml' ? normalise_xml(text) : normalise_html(text)
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
    r = system(command)
    #if r.nil? || $?.exitstatus > 1 #tidy is stupid and returns 1 on warning, 2 on failure.
    #  raise "tidy command failed '#{command}'"
    #end

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

  def create_user
    # TODO: We should setting a user in the spec files passing it to compare_static
    #       This is a really unexpected hack
    if User.any?
      User.last
    else
      FactoryGirl.create(
        :user,
        id: 1,
        name: "Henare Degan",
        confirmed_at: DateTime.parse("2013-10-20 10:10:53")
      )
    end
  end
end

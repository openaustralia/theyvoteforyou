# Originally from https://raw.github.com/openaustralia/planningalerts-app/d5b1ead73f220b7e56ef402bb833f51b2e5144d3/spec/html_compare_helper.rb

require 'open-uri'
require 'hpricot'

module HTMLCompareHelper
  def tidy(text)
    File.open("temp.html", "w") {|f| f.write(text) }
    # Requires HTML Tidy (http://tidy.sourceforge.net/) version 14 June 2007 or later
    system("/usr/local/bin/tidy --sort-attributes alpha -q -m temp.html")
    r = File.read("temp.html")
    # Make sure that comments of the form <!-- comment --> are followed by a new line
    File.delete("temp.html")
    r.gsub("--><", "-->\n<")
  end
  
  def compare_with_php(url, name, use_cache_file = false)
    cached_filename = File.dirname(__FILE__) + "/../regression_data/#{name}.html"
    if use_cache_file && File.exists?(cached_filename)
      expected = File.read(cached_filename)
    else
      # Setting User-Agent so that the php code outputs the default stylesheets
      expected = Hpricot(open("http://localhost#{url}", "User-Agent" => "Ruby/#{RUBY_VERSION}")).to_html
    end
    if use_cache_file && !File.exists?(cached_filename)
      File.open(cached_filename, "w") {|f| f.write(expected)}
    end
    
    get url
    result = Hpricot(@response.body).to_html

    expected_tidy = tidy(expected)
    result_tidy = tidy(result)
    if result_tidy == expected_tidy
      ["expected_#{name}.html", "result_#{name}.html", "expected_#{name}_tidy.html", "result_#{name}_tidy.html"].each do |f|
        File.delete(f) if File.exists?(f)
      end
    else
      # If failed then write out result for easy comparison
      File.open("expected_#{name}.html", "w") {|f| f.write(expected)}
      File.open("result_#{name}.html", "w") {|f| f.write(result)}
      File.open("expected_#{name}_tidy.html", "w") {|f| f.write(expected_tidy)}
      File.open("result_#{name}_tidy.html", "w") {|f| f.write(result_tidy)}
    end
    result_tidy.should == expected_tidy
  end
end
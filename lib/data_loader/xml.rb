require 'nokogiri'
require 'cgi'

module DataLoader
  class XML
    # Urgh, add extra HTML escaping that's done in PHP but not Ruby
    def self.escape_html(text)
      text = CGI::escape_html(text)
      text.gsub!('’', '&rsquo;')
      text.gsub('‘', '&lsquo;')
    end
  end
end

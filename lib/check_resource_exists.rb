require 'net/http'

class CheckResourceExists
  def self.call(url)
    uri = URI(url)
    res = Net::HTTP.start(uri.host) { |http| http.head(uri.path) }
    res.kind_of? Net::HTTPSuccess
  end
end

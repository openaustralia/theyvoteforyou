require 'net/http'

class CheckResourceExists
  def self.call(url)
    uri = URI(url)
    res = Net::HTTP.get_response(uri)
    res.kind_of? Net::HTTPSuccess
  end
end

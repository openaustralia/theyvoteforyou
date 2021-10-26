# frozen_string_literal: true

require "net/http"

class CheckResourceExists
  def self.call(url)
    uri = URI(url)
    res = Net::HTTP.get_response(uri)
    res.is_a? Net::HTTPSuccess
  end
end

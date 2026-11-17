# frozen_string_literal: true

class ApiStatistic < ApplicationRecord
  belongs_to :user

  def self.log(request, user:)
    create!(
      user: user,
      ip_address: request.remote_ip,
      query: path_without_key(request),
      user_agent: request.headers["User-Agent"]
    )
  end

  # user_id already says whose key it was, so the key itself needn't sit in the log for anyone reading it.
  # The other parameters are kept exactly as sent.
  def self.path_without_key(request)
    query = request.query_string.split("&").reject { |pair| key_param?(pair) }.join("&")
    query.empty? ? request.path : "#{request.path}?#{query}"
  end

  # Rails decodes names before reading params[:key], so "ke%79=" also reaches it as the key
  def self.key_param?(pair)
    Rack::Utils.unescape(pair.split("=").first.to_s) == "key"
  end
  private_class_method :key_param?
end

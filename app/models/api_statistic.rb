# frozen_string_literal: true

class ApiStatistic < ApplicationRecord
  belongs_to :user

  def self.log(request, user:)
    create!(
      user: user,
      ip_address: request.remote_ip,
      query: path_without_key(request.fullpath),
      user_agent: request.headers["User-Agent"]
    )
  end

  # user_id already says whose key it was, so the key itself needn't sit in the log for anyone reading it.
  # The other parameters are kept exactly as sent. Takes a path with its query string, as stored in query, since
  # rows from before #1871 still hold the key.
  def self.path_without_key(fullpath)
    path, query = fullpath.split("?", 2)
    query = query.to_s.split("&").reject { |pair| key_param?(pair) }.join("&")
    query.empty? ? path : "#{path}?#{query}"
  end

  # Rails decodes names before reading params[:key], so "ke%79=" also reaches it as the key. A name that can't be
  # decoded (e.g. "%zz") can't have been read as the key, so it's kept: older rows were stored as sent, and one
  # such row mustn't stop them being copied to Elasticsearch.
  def self.key_param?(pair)
    Rack::Utils.unescape(pair.split("=").first.to_s) == "key"
  rescue ArgumentError
    false
  end
  private_class_method :key_param?
end

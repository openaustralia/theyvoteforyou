# frozen_string_literal: true

class ApiStatistic < ApplicationRecord
  belongs_to :user

  def self.log(request, user:)
    create!(
      user: user,
      ip_address: request.remote_ip,
      query: request.fullpath,
      user_agent: request.headers["User-Agent"]
    )
  end
end

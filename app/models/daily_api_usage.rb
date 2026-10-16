# frozen_string_literal: true

# How many API requests each key made on each day (UTC), for the admin API usage page.
# api_statistics is too big to count on the fly, so this keeps a running total instead.
# Mirrors Planning Alerts' DailyApiUsage, see https://github.com/openaustralia/theyvoteforyou/issues/1789
class DailyApiUsage < ApplicationRecord
  belongs_to :user

  TopUser = Data.define(:user, :total, :mean, :min, :max)

  # A single upsert, so simultaneous requests can't both try to create the day's row
  def self.increment(user:, date: Time.current.utc.to_date)
    upsert({ user_id: user.id, date: date, count: 1 }, on_duplicate: Arel.sql("count = count + 1")) # rubocop:disable Rails/SkipsModelValidations
  end

  # The busiest keys between from and to (inclusive), with their mean, min and max requests per day.
  # Days without any requests count as zero.
  def self.top_users(from:, to:, limit: 50)
    days = (to - from).to_i + 1
    rows = where(date: from..to).group(:user_id).order(Arel.sql("SUM(count) DESC")).limit(limit)
                                .pluck(:user_id, Arel.sql("SUM(count)"), Arel.sql("COUNT(*)"), Arel.sql("MIN(count)"), Arel.sql("MAX(count)"))
    users = User.where(id: rows.map(&:first)).index_by(&:id)
    # There's no foreign key, so skip counts left behind by a user deleted outside the app
    rows.filter_map do |user_id, total, days_used, min, max|
      next unless users[user_id]

      TopUser.new(user: users[user_id], total: total.to_i, mean: total.to_f / days, min: days_used < days ? 0 : min, max: max)
    end
  end

  # Recounts one month from api_statistics, replacing whatever counts it had
  def self.rebuild_month(month)
    range = month.beginning_of_month.in_time_zone("UTC")...month.next_month.beginning_of_month.in_time_zone("UTC")
    counts = ApiStatistic.where(created_at: range).where.not(user_id: nil).group(:user_id, Arel.sql("DATE(created_at)")).count
    rows = counts.map { |(user_id, date), count| { user_id: user_id, date: date, count: count } }
    transaction do
      where(date: month.all_month).delete_all
      insert_all(rows) if rows.any? # rubocop:disable Rails/SkipsModelValidations
    end
  end
end

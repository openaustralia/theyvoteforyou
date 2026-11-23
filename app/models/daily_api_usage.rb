# frozen_string_literal: true

# How many API requests each key made on each day (UTC), for the admin API usage page.
# api_statistics is too big to count on the fly, so this keeps a running total instead.
# Mirrors Planning Alerts' DailyApiUsage, see https://github.com/openaustralia/theyvoteforyou/issues/1789
class DailyApiUsage < ApplicationRecord
  belongs_to :user

  TopUser = Data.define(:user, :total, :mean, :min, :max)

  # A single upsert, so simultaneous requests can't both try to create the day's row
  def self.increment(user:, date: Time.current.utc.to_date)
    upsert( # rubocop:disable Rails/SkipsModelValidations
      { user_id: user.id, date: date, count: 1 },
      on_duplicate: Arel.sql("count = count + 1")
    )
  end

  # The busiest keys between from and to (inclusive), with their mean, min and max requests per day.
  # Days without any requests count as zero.
  def self.top_users(from:, to:, limit: 50)
    days = (to - from).to_i + 1
    # Joining users skips counts left behind by a user deleted outside the app, as there's no foreign key.
    # Ordering ties by user keeps the list the same from one page load to the next.
    sums = %w[SUM(count) COUNT(*) MIN(count) MAX(count)].map { |sql| Arel.sql(sql) }
    rows = where(date: from..to).joins(:user).group(:user_id)
                                .order(Arel.sql("SUM(count) DESC"), :user_id).limit(limit)
                                .pluck(:user_id, *sums)
    users = User.where(id: rows.map(&:first)).index_by(&:id)
    rows.map do |user_id, total, days_used, min, max|
      TopUser.new(user: users[user_id], total: total.to_i, mean: total.to_f / days,
                  min: days_used < days ? 0 : min, max: max)
    end
  end

  Rebuilt = Data.define(:calls, :keys)

  # Recounts one UTC day from api_statistics, replacing whatever counts it had. A day at a time, as a whole
  # month's count on maindb took over 40 minutes and held up the site (#1916). A call made while this runs can
  # be lost from today's count, as the day's counts are replaced just after being taken.
  def self.rebuild_day(date)
    start = date.in_time_zone("UTC")
    counts = ApiStatistic.where(created_at: start...(start + 1.day)).where.not(user_id: nil).group(:user_id).count
    rows = counts.map { |user_id, count| { user_id: user_id, date: date, count: count } }
    transaction do
      where(date: date).delete_all
      insert_all(rows) if rows.any? # rubocop:disable Rails/SkipsModelValidations
    end
    Rebuilt.new(calls: counts.values.sum, keys: counts.size)
  end
end

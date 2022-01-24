class PopulateCreatedByOnOldWikiMotionsRecords < ActiveRecord::Migration[5.0]
  # This migration needs to be run before upgrading to Rails 5.1 as the timezone hack that
  # we're using breaks under Rails 5.1. This migration is a path to getting rid of that hack too.

  # We're overriding the default implementation so that we can have our timezone hack for the
  # "edit_date" attribute without aliasing the "created_at" attribute.
  class WikiMotion < ApplicationRecord
    def edit_date
      Time.zone.parse(self[:edit_date].in_time_zone("UTC").strftime("%F %T"))
    end

    def edit_date=(date)
      date_set_in_utc = date.strftime("%F %T #{date.in_time_zone('UTC').formatted_offset}")
      self[:edit_date] = date_set_in_utc
    end
  end

  def change
    WikiMotion.where(created_at: nil).find_each do |w|
      w.update!(created_at: w.edit_date)
    end
  end
end

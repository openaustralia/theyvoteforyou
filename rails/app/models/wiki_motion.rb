class WikiMotion < ActiveRecord::Base
  self.table_name = "pw_dyn_wiki_motion"

  belongs_to :user

  validates :title, presence: true

  attr_accessor :title, :description

  before_save :set_text_body, unless: :text_body

  def division
    Division.find_by(division_date: division_date, division_number: division_number, house: house)
  end

  # Strip timezone as it's stored in the DB as local time
  def edit_date
    Time.parse(read_attribute(:edit_date).strftime('%F %T'))
  end

  # FIXME: Stop this nonsense of storing local times in the DB to match PHP
  def edit_date=(date)
    write_attribute(:edit_date, date.strftime('%F %T'))
  end

  private

  def set_text_body
    self.text_body = <<-RECORD
--- DIVISION TITLE ---

#{title}

--- MOTION EFFECT ---

#{description}

--- COMMENTS AND NOTES ---

(put thoughts and notes for other researchers here)
    RECORD
  end
end

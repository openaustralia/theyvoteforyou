class WikiMotion < ActiveRecord::Base
  belongs_to :user

  validates :title, presence: true

  attr_accessor :title, :description

  before_save :set_text_body, unless: :text_body

  # TODO Remove this as soon as is possible
  alias_attribute :wiki_id, :id

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

  def previous_edit
    division.wiki_motions.find_by('edit_date < ?', edit_date)
  end

  def previous_description
    if previous_edit
      previous_edit.text_body[/--- MOTION EFFECT ---(.*)--- COMMENT/m, 1]
    else
      division.original_motion
    end
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

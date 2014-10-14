class WikiMotion < ActiveRecord::Base
  belongs_to :user
  belongs_to :division

  validates :title, :description, presence: true

  attr_accessor :title, :description
  alias_attribute :created_at, :edit_date
  before_save :set_text_body, unless: :text_body

  # Strip timezone as it's stored in the DB as local time
  def edit_date
    Time.parse(read_attribute(:edit_date).strftime('%F %T'))
  end

  # FIXME: Stop this nonsense of storing local times in the DB to match PHP
  def edit_date=(date)
    write_attribute(:edit_date, date.strftime('%F %T'))
  end

  # TODO Doing this horrible workaround to deal with storing local time in db
  def edit_date_without_timezone
    edit_date.strftime('%F %T')
  end

  def previous_edit
    division.wiki_motions.find_by('edit_date < ?', edit_date_without_timezone)
  end

  def title
    @title ||= text_body[/--- DIVISION TITLE ---(.*)--- MOTION EFFECT/m, 1]
  end

  def description
    @description ||= text_body[/--- MOTION EFFECT ---(.*)--- COMMENT/m, 1]
  end

  def previous_description
    if previous_edit
      previous_edit.description
    else
      division.original_motion
    end
  end

  def previous_title
    if previous_edit
      previous_edit.title
    else
      division.original_name
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

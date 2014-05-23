class WikiMotion < ActiveRecord::Base
  self.table_name = "pw_dyn_wiki_motion"

  belongs_to :division
  belongs_to :user

  validates :title, presence: true

  attr_accessor :title, :description

  before_save :set_text_body, unless: :text_body

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

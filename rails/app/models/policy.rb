class Policy < ActiveRecord::Base
  self.table_name = 'pw_dyn_dreammp'

  has_many :policy_divisions, foreign_key: :dream_id
  has_many :policy_member_distances, foreign_key: :dream_id
  has_many :divisions, through: :policy_divisions
  belongs_to :user

  validates :name, :description, :user_id, :private, presence: true
  validates :name, uniqueness: true

  alias_attribute :id, :dream_id

  # HACK: Not using an association due to the fact that policy_divisions doesn't include a division_id!
  def divisions
    policy_divisions.collect { |pd| pd.division }
  end

  def votes_count
    policy_divisions.count
  end

  def edited_motions_count
    divisions.select { |d| d.motion_edited? }.size
  end

  def unedited_motions
    votes_count - edited_motions_count
  end

  def status
    case private
    when 0
      'public'
    when 1
      'legacy Dream MP'
    when 2
      'provisional'
    end
  end
end

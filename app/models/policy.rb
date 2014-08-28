class Policy < ActiveRecord::Base
  has_many :policy_divisions
  has_many :divisions, through: :policy_divisions
  has_many :policy_person_distances, dependent: :destroy
  has_many :divisions, through: :policy_divisions
  belongs_to :user

  validates :name, :description, :user_id, :private, presence: true
  validates :name, uniqueness: true

  def vote_for_division(division)
    policy_division = division.policy_divisions.find_by(policy: self)
    policy_division.vote if policy_division
  end

  def votes_count
    policy_divisions.count
  end

  def edited_motions_count
    divisions.select { |d| d.motion_edited? }.count
  end

  def unedited_motions_count
    votes_count - edited_motions_count
  end

  def provisional?
    status == "provisional"
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

  def add_division(division, vote)
    # FIXME This logic is all over the place and too complex. Simplify
    if old_policy_division = division.policy_divisions.find_by(policy: self)
      changed_from = old_policy_division.vote unless old_policy_division.vote == vote
      # FIXME: Because PolicyDivision has no primary key we can't update or destroy old_policy_division directly
      PolicyDivision.delete_all division_id: division.id, policy: self
    elsif vote != '--'
      changed_from = 'non-voter'
    end

    if vote != '--'
      PolicyDivision.create! division_id: division.id, policy: self, vote: vote
    end

    delay.calculate_member_agreement_percentages!

    changed_from
  end

  def calculate_member_agreement_percentages!
    policy_person_distances.delete_all

    policy_divisions.each do |policy_division|
      Member.current_on(policy_division.date).where(house: policy_division.house).each do |member|
        member_vote = member.vote_on_division_without_tell(policy_division.division)

        attribute = if policy_division.strong_vote?
          if member_vote == 'absent'
            :nvotesabsentstrong
          elsif member_vote == policy_division.vote_without_strong
            :nvotessamestrong
          else
            :nvotesdifferstrong
          end
        else
          if member_vote == 'absent'
            :nvotesabsent
          elsif member_vote == policy_division.vote_without_strong
            :nvotessame
          else
            :nvotesdiffer
          end
        end

        PolicyPersonDistance.find_or_create_by(person_id: member.person_id, policy_id: id).increment!(attribute)
      end
    end

    policy_person_distances.reload.each do |pmd|
      pmd.update!({
        distance_a: Distance.distance_a(pmd.nvotessame, pmd.nvotesdiffer, pmd.nvotesabsent,
          pmd.nvotessamestrong, pmd.nvotesdifferstrong, pmd.nvotesabsentstrong),
        distance_b: Distance.distance_b(pmd.nvotessame, pmd.nvotesdiffer,
          pmd.nvotessamestrong, pmd.nvotesdifferstrong)
      })
    end
  end
end

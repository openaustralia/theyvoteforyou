class Policy < ActiveRecord::Base
  self.table_name = 'pw_dyn_dreammp'

  has_many :policy_divisions, foreign_key: :dream_id
  has_many :policy_member_distances, foreign_key: :dream_id, dependent: :destroy
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
    divisions.select { |d| d.motion_edited? }.count
  end

  def unedited_motions_count
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

  def add_division(division, vote)
    # FIXME This logic is all over the place and too complex. Simplify
    if old_policy_division = division.policy_divisions.find_by(policy: self)
      changed_from = old_policy_division.vote unless old_policy_division.vote == vote
      # FIXME: Because PolicyDivision has no primary key we can't update or destroy old_policy_division directly
      PolicyDivision.delete_all house: division.house, division_date: division.date, division_number: division.number, policy: self
    elsif vote != '--'
      changed_from = 'non-voter'
    end

    if vote != '--'
      PolicyDivision.create! house: division.house, division_date: division.date, division_number: division.number, policy: self, vote: vote
    end

    delay.calculate_member_agreement_percentages!

    changed_from
  end

  def calculate_member_agreement_percentages!
    policy_member_distances.delete_all

    policy_divisions.each do |policy_division|
      policy_division_vote = policy_division.vote
      policy_division_vote_strong = policy_division.strong_vote?

      Member.current_on(policy_division.date).in_australian_house(House.uk_to_australian(policy_division.house)).each do |member|
        member_vote = member.vote_on_division(policy_division.division)

        # FIXME: Can't simply use find_or_create_by here thanks to the missing primary key fartarsery
        policy_member_distance = PolicyMemberDistance.find_by(person: member.person, dream_id: id) || policy_member_distances.create!(member: member)

        if member_vote == 'absent' && policy_division_vote_strong
          policy_member_distance.increment! :nvotesabsentstrong
        elsif member_vote == 'absent'
          policy_member_distance.increment! :nvotesabsent
        elsif member_vote == policy_division_vote && policy_division_vote_strong
          policy_member_distance.increment! :nvotessamestrong
        elsif member_vote == policy_division_vote
          policy_member_distance.increment! :nvotessame
        elsif member_vote != policy_division_vote && policy_division_vote_strong
          policy_member_distance.increment! :nvotesdifferstrong
        elsif member_vote != policy_division_vote
          policy_member_distance.increment! :nvotesdiffer
        end
      end
    end

    policy_member_distances.reload.each do |pmd|
      pmd.update! distance_a: calculate_distance(pmd), distance_b: calculate_distance(pmd, false)
    end
  end

  private

  # This is coped from the PHP app, I don't really understand the how and why so far
  def calculate_distance(pmd, include_abstentions = true)
    nvotessame, nvotessamestrong, nvotesdiffer, nvotesdifferstrong = pmd.nvotessame, pmd.nvotessamestrong, pmd.nvotesdiffer, pmd.nvotesdifferstrong
    if include_abstentions
      nvotesabsent, nvotesabsentstrong = pmd.nvotesabsent, pmd.nvotesabsentstrong
    else
      nvotesabsent, nvotesabsentstrong = 0, 0
    end

    tlw = 5.0

    weight = nvotessame + tlw * nvotessamestrong +
             nvotesdiffer + tlw * nvotesdifferstrong + 0.2 *
             nvotesabsent + tlw * nvotesabsentstrong

    score = nvotesdiffer + tlw * nvotesdifferstrong + 0.1 *
            nvotesabsent + (tlw / 2) * nvotesabsentstrong

    weight == 0.0 ? -1.0 : score / weight
  end
end

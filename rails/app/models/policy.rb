class Policy < ActiveRecord::Base
  self.table_name = 'pw_dyn_dreammp'

  has_many :policy_divisions, foreign_key: :dream_id
  has_many :policy_member_distances, foreign_key: :dream_id, dependent: :destroy
  has_many :divisions, through: :policy_divisions
  has_one :policy_info, foreign_key: :dream_id
  belongs_to :user

  validates :name, :description, :user_id, :private, presence: true
  validates :name, uniqueness: true

  delegate :votes_count, :edited_motions_count, to: :policy_info, allow_nil: true

  alias_attribute :id, :dream_id

  # HACK: Not using an association due to the fact that policy_divisions doesn't include a division_id!
  def divisions
    policy_divisions.collect { |pd| pd.division }
  end

  def unedited_motions
    votes_count - edited_motions_count if policy_info
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

  def calculate_member_agreement_percentages!
    policy_member_distances.delete_all

    policy_divisions.each do |policy_division|
      policy_division_vote = policy_division.vote
      policy_division_vote_strong = policy_division.strong_vote?

      Member.current_on(policy_division.date).in_australian_house(House.uk_to_australian(policy_division.house)).each do |member|
        member_vote = member.vote_on_division(policy_division.division)
        policy_member_distance = policy_member_distances.find_or_create_by!(member: member)

        if member_vote == 'absent' && policy_division_vote_strong
          policy_member_distance.increment! :nvotesabsentstrong
        elsif member_vote == 'absent'
          policy_member_distance.increment! :nvotesabsent
        elsif member_vote == policy_division_vote && policy_division_vote_strong
          policy_member_distance.increment! :nvotessamestrong
        elsif member_vote == policy_division_vote
          policy_member_distance.increment! :nvotesame
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

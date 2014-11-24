class PolicyDivision < ActiveRecord::Base
  # Using proc form of meta so that associated IDs are set on create as well
  # See https://github.com/airblade/paper_trail/issues/185#issuecomment-11781496 for more details
  has_paper_trail meta: { policy_id: Proc.new{|pd| pd.policy_id}, division_id: Proc.new{|pd| pd.division_id} }
  belongs_to :policy
  belongs_to :division
  validates :policy, :division, presence: true
  validates :vote, inclusion: { in: %w(aye3 aye no no3) }
  after_save    :calculate_policy_member_distances, :alert_policy_watches
  after_destroy :calculate_policy_member_distances, :alert_policy_watches

  delegate :name, :house, :house_name, :date, :number, to: :division

  def strong_vote?
    vote == 'aye3' || vote == 'no3'
  end

  def vote_without_strong
    case vote
    when 'aye3'
      'aye'
    when 'no3'
      'no'
    else
      vote
    end
  end

  private

  def calculate_policy_member_distances
    policy.delay.calculate_member_distances!
  end

  def alert_policy_watches
    policy.alert_watches(versions.last)
  end
end

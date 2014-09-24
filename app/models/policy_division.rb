class PolicyDivision < ActiveRecord::Base
  # Using proc form of meta so that policy_id is set on create as well
  # See https://github.com/airblade/paper_trail/issues/185#issuecomment-11781496 for more details
  has_paper_trail meta: { policy_id: Proc.new{|pd| pd.policy_id} }
  belongs_to :policy
  belongs_to :division
  validates :policy, :division, presence: true
  validates :vote, inclusion: { in: %w(aye3 aye no no3) }

  delegate :name, :australian_house, :australian_house_name, :date, :number, :house, to: :division

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
end

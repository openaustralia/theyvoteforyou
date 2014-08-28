class PolicyDivision < ActiveRecord::Base
  belongs_to :policy

  delegate :name, :australian_house, :australian_house_name, :date, :number, :house, to: :division

  # TODO Make this an association
  def division
    Division.find(division_id)
  end

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

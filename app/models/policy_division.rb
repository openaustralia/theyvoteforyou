class PolicyDivision < ActiveRecord::Base
  belongs_to :policy

  alias_attribute :date, :division_date
  alias_attribute :number, :division_number
  # TODO Remove this as soon as possible
  alias_attribute :dream_id, :policy_id

  delegate :name, :australian_house, :australian_house_name, to: :division

  def division
    Division.find_by!(division_date: division_date, division_number: division_number, house: house)
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

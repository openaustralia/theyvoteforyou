class Vote < ActiveRecord::Base
  self.table_name = "pw_vote"
  belongs_to :division
  belongs_to :member, foreign_key: "mp_id"

  delegate :party, :party_long2, :name, :electorate, to: :member
  delegate :whip_guess, to: :whip
  delegate :date, to: :division

  def whip
    division.whips.where(party: party).first
  end

  # Was this part of a free vote?
  def free?
    whip_guess == "none"
  end

  def rebellion?
    !free? && vote != whip_guess
  end

  def role
    # TODO Take into account free votes
    if rebellion?
      "rebel"
    elsif !free?
      "loyal"
    else
      "free"
    end
  end
end

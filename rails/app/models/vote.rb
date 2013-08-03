class Vote < ActiveRecord::Base
  self.table_name = "pw_vote"
  belongs_to :division
  belongs_to :member, foreign_key: "mp_id"

  delegate :party, :name, :electorate, to: :member
  delegate :whip_guess, to: :whip
  delegate :date, to: :division

  def whip
    division.whips.where(party: party).first
  end

  def rebellion?
    whip_guess != "none" && vote != whip_guess
  end
end

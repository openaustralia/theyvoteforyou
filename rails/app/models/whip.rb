class Whip < ActiveRecord::Base
  self.table_name = "pw_cache_whip"
  belongs_to :division

  def attendance_fraction
    # TODO What if possible_votes == 0?
    (total_votes).to_f / possible_votes
  end

  def total_votes
    aye_votes + aye_tells + no_votes + no_tells + both_votes + abstention_votes
  end

  def party_name
    if party == "PRES"
      "President"
    else
      party
    end
  end

  # TODO Move this to a helper
  def attendance_percentage
    "%0.1f%" % (attendance_fraction * 100)
  end

  def majority_votes
    noes_in_majority? ? no_votes : aye_votes
  end

  def minority_votes
    noes_in_majority? ? aye_votes : no_votes
  end

  def noes_in_majority?
    division.aye_majority < 0
  end
end

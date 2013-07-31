class Whip < ActiveRecord::Base
  self.table_name = "pw_cache_whip"

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
end

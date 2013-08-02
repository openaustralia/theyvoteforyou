class Whip < ActiveRecord::Base
  self.table_name = "pw_cache_whip"
  belongs_to :division

  delegate :noes_in_majority?, to: :division

  def attendance_fraction
    # TODO What if possible_votes == 0?
    (total_votes).to_f / possible_votes
  end

  def total_votes
    aye_votes_including_tells + no_votes_including_tells + both_votes + abstention_votes
  end

  def aye_votes_including_tells
    aye_votes + aye_tells
  end

  def no_votes_including_tells
    no_votes + no_tells
  end

  def party_name
    if party == "PRES"
      "President"
    else
      party
    end
  end

  def whip_guess_majority
    if (whip_guess == "no" && noes_in_majority?) || whip_guess == "yes" && !noes_in_majority?
      "majority"
    elsif (whip_guess == "no" && !noes_in_majority?) || (whip_guess == "yes" && noes_in_majority?)
      "minority"
    end
  end

  # TODO Move this to a helper
  def attendance_percentage
    "%0.1f%" % (attendance_fraction * 100)
  end

  def majority_votes
    noes_in_majority? ? no_votes : aye_votes
  end

  def majority_votes_including_tells
    noes_in_majority? ? no_votes_including_tells : aye_votes_including_tells
  end

  def minority_votes
    noes_in_majority? ? aye_votes : no_votes
  end

  def minority_votes_including_tells
    noes_in_majority? ? aye_votes_including_tells : no_votes_including_tells
  end
end

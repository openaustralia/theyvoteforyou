class Whip < ActiveRecord::Base
  self.table_name = "pw_cache_whip"
  belongs_to :division

  delegate :noes_in_majority?, to: :division

  def free?
    whip_guess == "none"
  end

  def no_loyal
    if whip_guess == "no"
      no_votes_including_tells
    elsif whip_guess == "yes"
      aye_votes_including_tells
    else
      # Otherwise we'll just call the majority loyal
      # TODO Is that the right thing to do?
      majority_votes_including_tells
    end
  end

  def no_rebels
    if whip_guess == "no"
      aye_votes_including_tells
    elsif whip_guess == "yes"
      no_votes_including_tells
    else
      # Otherwise we'll just call the minority rebels
      # TODO Is that the right thing to do?
      minority_votes_including_tells
    end
  end

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
    Party.long_name(party)
  end

  def whip_guess_majority
    if (whip_guess == "no" && noes_in_majority?) || whip_guess == "yes" && !noes_in_majority?
      "majority"
    elsif (whip_guess == "no" && !noes_in_majority?) || (whip_guess == "yes" && noes_in_majority?)
      "minority"
    end
  end

  def majority_votes
    noes_in_majority? ? no_votes : aye_votes
  end

  def majority_votes_including_tells
    noes_in_majority? ? no_votes_including_tells : aye_votes_including_tells
  end

  def majority_tells_votes
    noes_in_majority? ? no_tells : aye_tells
  end

  def minority_tells_votes
    noes_in_majority? ? aye_tells : no_tells
  end

  def minority_votes
    noes_in_majority? ? aye_votes : no_votes
  end

  def minority_votes_including_tells
    noes_in_majority? ? aye_votes_including_tells : no_votes_including_tells
  end
end

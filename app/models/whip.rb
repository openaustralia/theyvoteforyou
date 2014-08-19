class Whip < ActiveRecord::Base
  self.table_name = "pw_cache_whip"
  belongs_to :division

  delegate :noes_in_majority?, to: :division

  def self.update_all!
    # TODO Refactor this into an association
    possible_votes = Division.joins("LEFT JOIN pw_mp ON pw_division.house = pw_mp.house AND pw_mp.entered_house <= pw_division.division_date AND pw_division.division_date < pw_mp.left_house").group("pw_division.division_id", :party).count

    calc_all_votes_per_party2.each do |k, votes|
      whip = Whip.find_or_initialize_by(division_id: k[0], party: k[1])
      whip.aye_votes = votes["aye"] || 0
      whip.aye_tells = votes["tellaye"] || 0
      whip.no_votes = votes["no"] || 0
      whip.no_tells = votes["tellno"] || 0
      whip.both_votes = votes["both"] || 0
      whip.abstention_votes = votes["abstention"] || 0
      whip.possible_votes = possible_votes[[k[0], k[1]]]
      whip.whip_guess = calc_whip_guess(whip.aye_votes_including_tells, whip.no_votes_including_tells,
        whip.abstention_votes)
      whip.save!
    end
  end

  def self.calc_whip_guess(ayes, noes, abstentions)
    if ayes > noes && ayes > abstentions
      "aye"
    elsif noes > ayes && noes > abstentions
      "no"
    elsif abstentions > ayes && abstentions > noes
      "abstention"
    else
      "unknown"
    end
  end

  def self.calc_all_votes_per_party
    Division.joins(:votes => :member).group("pw_division.division_id", :party, :vote).count
  end

  def self.calc_all_votes_per_party2
    r = {}
    calc_all_votes_per_party.each do |k, count|
      votes = r[[k[0], k[1]]] || {}
      votes[k[2]] = count
      r[[k[0], k[1]]] = votes
    end
    r
  end

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
    if whip_guess == "none"
      nil
    elsif (whip_guess == "no" && noes_in_majority?) || (whip_guess == "aye" && !noes_in_majority?)
      "majority"
    elsif (whip_guess == "no" && !noes_in_majority?) || (whip_guess == "aye" && noes_in_majority?)
      "minority"
    else
      raise
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

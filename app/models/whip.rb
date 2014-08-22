class Whip < ActiveRecord::Base
  self.table_name = "pw_cache_whip"
  belongs_to :division

  delegate :noes_in_majority?, to: :division

  def self.update_all!
    possible_votes = Division.joins("LEFT JOIN members ON pw_division.house = members.house AND members.entered_house <= pw_division.division_date AND pw_division.division_date < members.left_house").group("pw_division.division_id", :party).count

    calc_all_votes_per_party2.each do |k, votes|
      division_id, party = k
      # TODO Use find_or_initialize_by when the table has a primary id rather than this tortuous deleting
      # and recreating nonsense
      Whip.transaction do
        Whip.where(division_id: division_id, party: party).delete_all
        whip = Whip.new(division_id: division_id, party: party)

        whip.aye_votes = votes["aye"] || 0
        whip.aye_tells = votes["tellaye"] || 0
        whip.no_votes = votes["no"] || 0
        whip.no_tells = votes["tellno"] || 0
        whip.both_votes = votes["both"] || 0
        whip.abstention_votes = votes["abstention"] || 0
        whip.possible_votes = possible_votes[[division_id, party]]
        if Party.whipless?(whip.party) || whip.free_vote?
          whip.whip_guess = "none"
        else
          whip.whip_guess = calc_whip_guess(whip.aye_votes_including_tells, whip.no_votes_including_tells,
            whip.abstention_votes)
        end
        whip.save!
      end
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

  # TODO Move the info about which votes are free to the database
  def free_vote?
    # Conscience / free votes from 2006 and onwards. This list from Appendix 3 of
    # http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id%3A%22library%2Fprspub%2FCQOS6%22
    # TODO: Do we need to restrict this to only these parties? Are these votes free for all parties?

    # The ALP decided at national conference to have a conscience vote on gay marriage
    # See http://www.abc.net.au/news/2011-12-03/labor-votes-for-conscience-vote-on-same-sex-marriage/3710828

    if division.australian_house == "representatives"
      # Therapeutic Goods Amendment (Repeal of Ministerial Responsibility for Approval of  RU486) Bill 2005
      if division.division_date == Date.new(2006,2,16)
        ['Liberal Party', 'National Party', 'Australian Labor Party', 'Australian Democrats'].include?(party)
      # Prohibition of Human Cloning for Reproduction and the Regulation of Human Embryo Research Amendment Bill
      elsif division.division_date == Date.new(2006,12,6)
        ['Liberal Party', 'National Party', 'Australian Labor Party', 'Australian Democrats'].include?(party)
      # Same sex marriage
      elsif division.division_date == Date.new(2012,9,19) && division.division_number == 1
        party == 'Australian Labor Party'
      end
    elsif division.australian_house == "senate"
      # Therapeutic Goods Amendment (Repeal of Ministerial Responsibility for Approval of  RU486) Bill 2005
      if division.division_date == Date.new(2006,2,9) && division.division_number >= 3
        ['Liberal Party', 'National Party', 'Australian Labor Party', 'Australian Democrats'].include?(party)
      # Prohibition of Human Cloning for Reproduction and the Regulation of Human Embryo Research Amendment Bill 2006
    elsif division.division_date == Date.new(2006,11,7) &&
      (division.division_number == 1 || division.division_number >= 4)
        ['Liberal Party', 'National Party', 'Australian Labor Party', 'Australian Democrats'].include?(party)
      # Same sex marriage
      elsif division.division_date == Date.new(2012,9,20) && division.division_number == 5
        party == 'Australian Labor Party'
      # Same sex marriage
      elsif division.division_date == Date.new(2013,6,20) && division.division_number == 2
        party == 'Australian Labor Party'
      end
    end
  end

  # TODO combine methods free? and free_votes? into one. They do pretty much the same thing.
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

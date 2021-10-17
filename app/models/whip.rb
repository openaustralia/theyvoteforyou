# frozen_string_literal: true

class Whip < ApplicationRecord
  belongs_to :division

  def self.update_all!
    all_possible_votes = Division.joins("LEFT JOIN members ON divisions.house = members.house AND members.entered_house <= divisions.date AND divisions.date < members.left_house").group("divisions.id", :party).count
    all_votes = calc_all_votes_per_party2

    all_possible_votes.each_key do |division_id, party|
      votes = all_votes[[division_id, party]]
      possible_votes = all_possible_votes[[division_id, party]]

      whip = Whip.find_or_initialize_by(division_id: division_id, party: party)

      if votes
        whip.aye_votes = votes[["aye", 0]] || 0
        whip.aye_tells = votes[["aye", 1]] || 0
        whip.no_votes = votes[["no", 0]] || 0
        whip.no_tells = votes[["no", 1]] || 0
        whip.both_votes = votes[["both", 0]] || 0
        whip.abstention_votes = votes[["abstention", 0]] || 0
      else
        whip.aye_votes = 0
        whip.aye_tells = 0
        whip.no_votes = 0
        whip.no_tells = 0
        whip.both_votes = 0
        whip.abstention_votes = 0
      end

      whip.possible_votes = possible_votes || 0
      whip.whip_guess = whip.calc_whip_guess
      whip.save!
    end
  end

  def calc_whip_guess
    if whipless? || free_vote?
      "none"
    else
      Whip.calc_whip_guess(aye_votes_including_tells, no_votes_including_tells, abstention_votes)
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
    Division.joins(votes: :member).group("divisions.id", :party, :vote, :teller).count
  end

  def self.calc_all_votes_per_party2
    r = {}
    calc_all_votes_per_party.each do |k, count|
      division_id, party, vote, teller = k
      votes = r[[division_id, party]] || {}
      votes[[vote, teller]] = count
      r[[division_id, party]] = votes
    end
    r
  end

  # TODO: Move the info about which votes are free to the database
  # rubocop:disable Lint/DuplicateBranch
  def free_vote?
    # Free votes from 2006 and onwards. This list from Appendix 3 of
    # http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id%3A%22library%2Fprspub%2FCQOS6%22
    # TODO: Do we need to restrict this to only these parties? Are these votes free for all parties?

    # The ALP decided at national conference to have a free vote on gay marriage
    # See http://www.abc.net.au/news/2011-12-03/labor-votes-for-conscience-vote-on-same-sex-marriage/3710828

    case division.house
    when "representatives"
      # Therapeutic Goods Amendment (Repeal of Ministerial Responsibility for Approval of  RU486) Bill 2005
      if division.date == Date.new(2006, 2, 16)
        ["Liberal Party", "National Party", "Australian Labor Party", "Australian Democrats"].include?(party)
      # Prohibition of Human Cloning for Reproduction and the Regulation of Human Embryo Research Amendment Bill
      elsif division.date == Date.new(2006, 12, 6)
        ["Liberal Party", "National Party", "Australian Labor Party", "Australian Democrats"].include?(party)
      # Same sex marriage
      elsif division.date == Date.new(2012, 9, 19) && division.number == 1
        party == "Australian Labor Party"
      # Marriage Amendment (Definition and Religious Freedoms) Bill 2017
      elsif division.date == Date.new(2017, 12, 7)
        # Assuming that only the two major parties had a free vote
        ["Liberal Party", "National Party", "Australian Labor Party"].include?(party)
      end
    when "senate"
      # Therapeutic Goods Amendment (Repeal of Ministerial Responsibility for Approval of  RU486) Bill 2005
      if division.date == Date.new(2006, 2, 9) && division.number >= 3
        ["Liberal Party", "National Party", "Australian Labor Party", "Australian Democrats"].include?(party)
      # Prohibition of Human Cloning for Reproduction and the Regulation of Human Embryo Research Amendment Bill 2006
      elsif division.date == Date.new(2006, 11, 7) && (division.number == 1 || division.number >= 4)
        ["Liberal Party", "National Party", "Australian Labor Party", "Australian Democrats"].include?(party)
      # Same sex marriage
      elsif division.date == Date.new(2012, 9, 20) && division.number == 5
        party == "Australian Labor Party"
      # Same sex marriage
      elsif division.date == Date.new(2013, 6, 20) && division.number == 2
        party == "Australian Labor Party"
      # Marriage Amendment (Definition and Religious Freedoms) Bill 2017
      elsif division.date == Date.new(2017, 11, 28) && [1, 2, 4, 5, 6, 7, 9].include?(division.number)
        # Assuming that only the two major parties had a free vote
        ["Liberal Party", "National Party", "Australian Labor Party"].include?(party)
      # Marriage Amendment (Definition and Religious Freedoms) Bill 2017
      elsif division.date == Date.new(2017, 11, 29) && [1, 2, 4, 7].include?(division.number)
        # Assuming that only the two major parties had a free vote
        ["Liberal Party", "National Party", "Australian Labor Party"].include?(party)
      elsif division.date == Date.new(2018, 8, 15) && division.number == 8
        ["Liberal Party", "National Party", "Australian Labor Party", "Pauline Hanson's One Nation Party"].include?(party)
      elsif division.date == Date.new(2018, 12, 4) && division.number == 12
        party == "Liberal Party"
      elsif division.date == Date.new(2019, 10, 16) && division.number == 3
        # Congratulate NSW on decriminalising abortion
        party == "Liberal Party" # Probably other parties too, but the Libs were the only party with 'rebellions'
      end
    end
    # rubocop:enable Lint/DuplicateBranch
  end

  # TODO: combine methods free? and free_votes? into one. They do pretty much the same thing.
  def free?
    whip_guess == "none"
  end

  def no_loyal
    if whip_guess == "no"
      no_votes_including_tells
    elsif whip_guess == "aye"
      aye_votes_including_tells
    else
      # TODO: Is that the right thing to do?
      division.aye_majority.negative? ? no_votes_including_tells : aye_votes_including_tells
    end
  end

  def no_rebels
    if whip_guess == "no"
      aye_votes_including_tells
    elsif whip_guess == "aye"
      no_votes_including_tells
    else
      # TODO: Is that the right thing to do?
      division.aye_majority.negative? ? aye_votes_including_tells : no_votes_including_tells
    end
  end

  def attendance_fraction
    total_votes.to_f / possible_votes unless possible_votes.zero?
  end

  # a tie is 0.0. a unanimous vote is 1.0
  def majority_fraction
    case calc_whip_guess
    when "aye"
      aye_votes_including_tells.to_f / total_votes
    when "no"
      no_votes_including_tells.to_f / total_votes
    else
      0.0
    end
  end

  def unanimous?
    aye_votes_including_tells == total_votes ||
      no_votes_including_tells == total_votes
  end

  # Just following this logic through in refactoring. It doesn't
  # line up with an intuitive sense of what this function should do
  # TODO: Fix this
  def tied?
    calc_whip_guess != "aye" && calc_whip_guess != "no"
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

  def party_object
    @party_object ||= Party.new(name: party)
  end

  def party_name
    party_object.long_name
  end

  def whipless?
    party_object.whipless?
  end
end

class Vote < ActiveRecord::Base
  self.table_name = "pw_vote"
  belongs_to :division
  belongs_to :member, foreign_key: "mp_id"

  delegate :party, :party_long2, :name, :name_without_title, :electorate, to: :member
  delegate :whip_guess, :free?, to: :whip
  delegate :date, to: :division

  def whip
    division.whips.where(party: party).first
  end

  # All rebellious votes
  # TODO Rename to rebellions
  def self.rebellious
    joins(:member, {:division => :whips}).where("pw_cache_whip.party = pw_mp.party").
      where("(pw_cache_whip.whip_guess = 'aye' AND (pw_vote.vote = 'no' OR pw_vote.vote = 'tellno' OR pw_vote.vote = 'abstention')) OR (pw_cache_whip.whip_guess = 'no' AND (pw_vote.vote = 'aye' OR pw_vote.vote = 'tellaye' OR pw_vote.vote = 'abstention')) OR (pw_cache_whip.whip_guess = 'abstention' AND (pw_vote.vote = 'aye' OR pw_vote.vote = 'tellaye' OR pw_vote.vote = 'no' OR pw_vote.vote = 'tellno'))")
  end

  def self.tells
    where("pw_vote.vote = 'tellaye' OR pw_vote.vote = 'tellno'")
  end

  def self.ayes
    where("pw_vote.vote = 'aye' OR pw_vote.vote = 'tellaye'")
  end

  def self.noes
    where("pw_vote.vote = 'no' OR pw_vote.vote = 'tellno'")
  end

  def rebellion?
    !free? && vote_without_tell != whip_guess
  end

  def teller?
    vote[0..3] == 'tell'
  end

  def vote_without_tell
    vote.gsub('tell', '')
  end

  def role
    if teller? && free?
      "free teller"
    elsif teller? && rebellion?
      "rebel teller"
    elsif teller?
      "teller"
    elsif rebellion?
      "rebel"
    elsif free?
      "free"
    else
      "loyal"
    end
  end
end

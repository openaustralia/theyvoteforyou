class Vote < ActiveRecord::Base
  belongs_to :division
  belongs_to :member

  delegate :party, :party_long2, :name, :name_without_title, :electorate, to: :member
  delegate :whip_guess, :free?, to: :whip
  delegate :date, to: :division

  def whip
    division.whips.where(party: party).first
  end

  # All rebellious votes
  # TODO Rename to rebellions
  def self.rebellious
    joins(:member, {:division => :whips}).where("whips.party = members.party").
      where("(whips.whip_guess = 'aye' AND (votes.vote = 'no' OR votes.vote = 'tellno' OR votes.vote = 'abstention')) OR (whips.whip_guess = 'no' AND (votes.vote = 'aye' OR votes.vote = 'tellaye' OR votes.vote = 'abstention')) OR (whips.whip_guess = 'abstention' AND (votes.vote = 'aye' OR votes.vote = 'tellaye' OR votes.vote = 'no' OR votes.vote = 'tellno'))")
  end

  def self.tells
    where("votes.vote = 'tellaye' OR votes.vote = 'tellno'")
  end

  def self.ayes
    where("votes.vote = 'aye' OR votes.vote = 'tellaye'")
  end

  def self.noes
    where("votes.vote = 'no' OR votes.vote = 'tellno'")
  end

  def rebellion?
    !free? && vote_without_tell != whip_guess
  end

  # TODO What if the vote is tied?
  def role
    if free?
      "free"
    elsif rebellion?
      "rebel"
    else
      "loyal"
    end
  end
end

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
      where("(whips.whip_guess = 'aye' AND (votes.vote_without_tell = 'no' OR votes.vote_without_tell = 'abstention')) OR (whips.whip_guess = 'no' AND (votes.vote_without_tell = 'aye' OR votes.vote_without_tell = 'abstention')) OR (whips.whip_guess = 'abstention' AND (votes.vote_without_tell = 'aye' OR votes.vote_without_tell = 'no'))")
  end

  def self.tells
    where(teller: true)
  end

  def self.ayes
    where("votes.vote_without_tell = 'aye'")
  end

  def self.noes
    where("votes.vote_without_tell = 'no'")
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

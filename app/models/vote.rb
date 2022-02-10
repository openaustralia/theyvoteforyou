# frozen_string_literal: true

class Vote < ApplicationRecord
  belongs_to :division
  belongs_to :member

  delegate :party, :name, :electorate, to: :member
  delegate :whip_guess, :free?, to: :whip
  delegate :date, to: :division

  def whip
    division.whips.find_by(party: party)
  end

  # All rebellious votes
  # TODO Rename to rebellions
  def self.rebellious
    joins(:member, { division: :whips }).where("whips.party = members.party")
                                        .where("(whips.whip_guess = 'aye' AND (votes.vote = 'no' OR votes.vote = 'abstention')) OR (whips.whip_guess = 'no' AND (votes.vote = 'aye' OR votes.vote = 'abstention')) OR (whips.whip_guess = 'abstention' AND (votes.vote = 'aye' OR votes.vote = 'no'))")
  end

  def self.tells
    where(teller: true)
  end

  def self.ayes
    where("votes.vote = 'aye'")
  end

  def self.noes
    where("votes.vote = 'no'")
  end

  def rebellion?
    !free? && vote != whip_guess
  end

  # TODO: What if the vote is tied?
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

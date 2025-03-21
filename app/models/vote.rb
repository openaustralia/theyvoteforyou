# frozen_string_literal: true

class Vote < ApplicationRecord
  # TODO: I would expect vote should be null: false in the schema
  belongs_to :division
  belongs_to :member

  delegate :party, :party_name, :name, :electorate, to: :member
  delegate :whip_guess, :free?, :free_vote?, to: :whip
  delegate :date, to: :division

  # TODO: Check that this isn't being used somewhere unexpected
  def whip
    # Assuming that the whips are preloaded for the division so it's more sensible to find the correct
    # whip record by searching in memory rather than creating another request to the database
    division.whips.find { |w| w.party == party }
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
end

# frozen_string_literal: true

module VotesHelper
  def vote_words(vote)
    if vote
      if vote.rebellion?
        "voted #{vote_display(vote.vote)}, rebelling against the #{vote.party_name}"
      elsif vote.free_vote?
        "voted #{vote_display(vote.vote)} in this free vote"
      else
        "voted #{vote_display(vote.vote)}"
      end
    else
      "was absent"
    end
  end
end

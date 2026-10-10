# frozen_string_literal: true

module VotesHelper
  # Finds the votes these members cast in these divisions with one query, keyed by [member_id, division_id], so
  # that a list of divisions does not look each vote up one division at a time. The votes come with their member
  # and with their division's whips, because vote_words needs both and Vote#whip assumes the whips are loaded.
  def votes_by_member_and_division(members, divisions)
    members = members.compact
    division_ids = divisions.to_a.map(&:id)
    return {} if members.empty? || division_ids.empty?

    Vote.where(member: members, division_id: division_ids)
        .includes(:member, division: :whips)
        .index_by { |vote| [vote.member_id, vote.division_id] }
  end

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

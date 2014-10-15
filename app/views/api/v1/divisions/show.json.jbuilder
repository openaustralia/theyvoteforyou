json.partial! "division", division: @division

# Extra information that isn't in the summary
json.summary @division.motion
json.markdown @division.markdown?
json.votes do
  json.array! @division.votes.order(:vote) do |vote|
    json.vote vote.vote
    json.member do
      json.partial! "api/v1/members/member", member: vote.member
    end
  end
end

json.policy_divisions do
  json.array! @division.policy_divisions do |pd|
    json.policy do
      json.partial! "api/v1/policies/policy", policy: pd.policy
    end
    json.vote pd.vote_without_strong
    json.strong pd.strong_vote?
  end
end

json.bills do
  json.array! @division.bills do |bill|
    json.id bill.id
    json.official_id bill.official_id
    json.title bill.title
    json.url bill.url
  end
end

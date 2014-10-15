json.partial! "division", division: @division

# Extra information that isn't in the summary
json.summary @division.motion
json.votes @division.votes.order(:vote), partial: "api/v1/votes/vote", as: :vote

json.policy_divisions do
  json.array! @division.policy_divisions do |pd|
    json.policy do
      json.partial! "api/v1/policies/policy", policy: pd.policy
    end
    json.vote pd.vote_without_strong
    json.strong pd.strong_vote?
  end
end

json.bills @division.bills, partial: "api/v1/bills/bill", as: :bill

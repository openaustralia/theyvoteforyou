# frozen_string_literal: true

json.partial! "policy", policy: @policy

# More detailed information
json.policy_divisions do
  json.array! @policy.policy_divisions.includes(division: %i[wiki_motions whips division_info]) do |pd|
    json.division do
      json.partial! "api/v1/divisions/division", division: pd.division
    end
    json.vote PolicyDivision.vote_without_strong(pd.vote)
    json.strong pd.strong_vote?
  end
end

json.people_comparisons do
  json.array! @policy.policy_person_distances.includes(person: :members).order(:distance_a) do |ppd|
    json.person do
      json.partial! "api/v1/people/person", person: ppd.person
    end
    json.agreement number_with_precision(ppd.agreement_fraction * 100, precision: 2, significant: true)
    json.voted ppd.voted?
    json.category ppd.category
  end
end

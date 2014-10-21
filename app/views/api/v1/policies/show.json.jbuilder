json.partial! "policy", policy: @policy

# More detailed information
json.policy_divisions do
  json.array! @policy.policy_divisions.includes(:division => [:wiki_motions, :whips, :division_info]) do |pd|
    json.division do
      json.partial! "api/v1/divisions/division", division: pd.division
    end
    json.vote pd.vote_without_strong
    json.strong pd.strong_vote?
  end
end

json.people_comparisons do
  json.array! @policy.policy_person_distances.includes(:person => :members).order(:distance_a) do |ppd|
    json.person do
      json.partial! "api/v1/people/person", person: ppd.person
    end
    json.agreement number_with_precision(ppd.agreement_fraction * 100,  precision: 2, significant: true)
    json.voted ppd.voted?
  end
end

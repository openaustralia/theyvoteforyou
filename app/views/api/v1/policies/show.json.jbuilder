json.id @policy.id
json.name @policy.name
json.description @policy.description
json.provisional @policy.provisional?

# More detailed information
json.policy_divisions do
  json.array! @policy.policy_divisions do |pd|
    json.division do
      json.id pd.division.id
      json.house pd.division.australian_house
      json.name pd.division.name
      json.date pd.division.date
      json.number pd.division.number
    end
    json.vote pd.vote_without_strong
    json.strong pd.strong_vote?
  end
end


json.people_comparisons do
  json.array! @policy.policy_person_distances.order(:distance_a) do |ppd|
    json.person do
      json.id ppd.person.id
      member = ppd.person.latest_member
      json.name do
        json.first member.first_name
        json.last member.last_name
      end
      json.electorate member.electorate
      json.house member.australian_house
      json.party member.party
    end
    json.agreement number_with_precision(ppd.agreement_fraction * 100,  precision: 2, significant: true)
    json.voted ppd.voted?
  end
end

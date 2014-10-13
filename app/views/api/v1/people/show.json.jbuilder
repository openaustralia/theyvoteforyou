member = @person.latest_member
json.name do
  json.first member.first_name
  json.last member.last_name
end
json.electorate member.electorate
json.house member.australian_house
json.party member.party

# Extra information that's not on the index action

json.rebellions @person.rebellions
json.votes_attended @person.votes_attended
json.votes_possible @person.votes_possible

json.offices do
  json.array! @person.current_offices do |office|
    json.position office.position
  end
end

json.policy_comparisons do
  json.array! @person.policy_person_distances.order(:distance_a) do |ppd|
    json.policy do
      json.id ppd.policy.id
      json.name ppd.policy.name
      json.description ppd.policy.description
      json.provisional ppd.policy.provisional?
    end
    json.agreement number_with_precision(ppd.agreement_fraction * 100,  precision: 2, significant: true)
    json.voted ppd.voted?
  end
end

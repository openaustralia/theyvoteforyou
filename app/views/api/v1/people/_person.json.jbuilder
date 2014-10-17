json.id person.id
json.latest_member do
  json.id person.latest_member.id
  json.name do
    json.first person.latest_member.first_name
    json.last person.latest_member.last_name
  end
  json.electorate person.latest_member.electorate
  json.house person.latest_member.house
  json.party person.latest_member.party
end

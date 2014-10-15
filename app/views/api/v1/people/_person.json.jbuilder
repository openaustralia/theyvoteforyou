json.id person.id
member = person.latest_member
json.name do
  json.first member.first_name
  json.last member.last_name
end
json.electorate member.electorate
json.house member.australian_house
json.party member.party

json.array! @people do |person|
  json.id person.id
  member = person.latest_member
  json.first_name member.first_name
  json.last_name member.last_name
  json.electorate member.electorate
  json.house member.australian_house
  json.party member.party
  json.entered_house_on member.entered_house
  # json.body comment.body
  # json.author do
  #   json.first_name comment.author.first_name
  #   json.last_name comment.author.last_name
  # end
end

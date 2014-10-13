json.array! @people do |person|
  json.id person.id
  member = person.latest_member
  json.name do
    json.first member.first_name
    json.last member.last_name
  end
  json.electorate member.electorate
  json.house member.australian_house
  json.party member.party
  json.start_date member.entered_house
  # json.body comment.body
  # json.author do
  #   json.first_name comment.author.first_name
  #   json.last_name comment.author.last_name
  # end
end

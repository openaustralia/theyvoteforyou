json.array! @divisions do |division|
  json.id division.id
  json.house division.australian_house
  json.name division.name
  json.date division.date
  json.number division.number
  json.aye_votes division.aye_votes
  json.no_votes division.no_votes
  json.possible_turnout division.division_info.possible_turnout
  json.rebellions division.division_info.rebellions
end

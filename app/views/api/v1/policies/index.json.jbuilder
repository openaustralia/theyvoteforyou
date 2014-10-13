json.array! @policies do |policy|
  json.id policy.id
  json.name policy.name
  json.description policy.description
  json.provisional policy.provisional?
end

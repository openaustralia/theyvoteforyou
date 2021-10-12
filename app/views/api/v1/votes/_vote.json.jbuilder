# frozen_string_literal: true

json.vote vote.vote
json.member do
  json.partial! "api/v1/members/member", member: vote.member
end

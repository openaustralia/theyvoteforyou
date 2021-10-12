# frozen_string_literal: true

module PathHelper
  def electorate_path(member)
    Rails.application.routes.url_helpers.electorate_path(electorate_params(member))
  end

  def party_divisions_path(party_object)
    Rails.application.routes.url_helpers.party_divisions_path(party: party_object.url_name)
  end

  def member_division_path(member, division)
    Rails.application.routes.url_helpers
         .member_division_path(division_params(division).merge(member_params(member)))
  end

  def division_path(division, q = {})
    Rails.application.routes.url_helpers.division_path(q.merge(division_params(division)))
  end

  def history_division_path(division)
    Rails.application.routes.url_helpers.history_division_path(division_params(division))
  end

  def edit_division_path(division)
    Rails.application.routes.url_helpers.edit_division_path(division_params(division))
  end

  def member_path(member)
    Rails.application.routes.url_helpers.member_path(member_params(member))
  end

  def member_policy_path(member, policy)
    Rails.application.routes.url_helpers.member_policy_path(member_params(member).merge(id: policy.id))
  end

  def member_divisions_path(member)
    Rails.application.routes.url_helpers.member_divisions_path(member_params(member))
  end

  def friends_member_path(member)
    Rails.application.routes.url_helpers.friends_member_path(member_params(member))
  end

  def electorate_params(member)
    {
      mpc: member&.url_electorate&.downcase,
      house: member&.house
    }
  end

  def member_params(member)
    electorate_params(member).merge(mpn: member.url_name.downcase)
  end

  def division_params(division)
    {
      date: division.date,
      number: division.number,
      house: division.house
    }
  end
end

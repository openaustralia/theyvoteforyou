# frozen_string_literal: true

module PathHelper
  def member_division_path(member, division)
    Rails.application.routes.url_helpers
         .member_division_path(division_params(division).merge(member_params(member)))
  end

  def division_path(division, options = {})
    Rails.application.routes.url_helpers.division_path(options.merge(division_params(division)))
  end

  def division_url(division, options = {})
    Rails.application.routes.url_helpers.division_url(options.merge(division_params(division)))
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

  def member_params(member)
    {
      house: member&.house,
      mpc: member&.url_electorate&.downcase,
      mpn: member.url_name.downcase
    }
  end

  def division_params(division)
    {
      date: division.date,
      number: division.number,
      house: division.house
    }
  end
end

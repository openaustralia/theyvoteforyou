module PathHelper
  def electorate_path(member)
    Rails.application.routes.url_helpers.electorate_path(electorate_params(member))
  end

  def party_divisions_path2(party)
    party_divisions_path(party: party.downcase.gsub(" ", "_"))
  end

  def member_division_path2(member, division)
    member_division_path(division_params(division).merge(member_params(member)))
  end

  def division_with_policy_path(division, policy)
    if policy
      dmp = policy.id
    elsif current_user
      dmp = current_user.active_policy_id
    end
    if dmp
      division_policy_path(division_params(division).merge(dmp: dmp))
    else
      division_policies_path(division_params(division))
    end
  end

  def division_path(division, q = {})
    Rails.application.routes.url_helpers.division_path(q.merge(division_params(division)))
  end

  def history_division_path2(division)
    history_division_path(division_params(division))
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

  def full_member_policy_path(member, policy)
    Rails.application.routes.url_helpers.full_member_policy_path(member_params(member).merge(id: policy.id))
  end

  def member_divisions_path(member)
    Rails.application.routes.url_helpers.member_divisions_path(member_params(member))
  end

  def friends_member_path(member)
    Rails.application.routes.url_helpers.friends_member_path(member_params(member))
  end

  def electorate_params(member)
    {
      mpc: (member.url_electorate.downcase if member),
      house: (member.australian_house if member)
    }
  end

  def member_params(member)
    electorate_params(member).merge(mpn: member.url_name.downcase)
  end

  def division_params(division)
    {
      date: division.date,
      number: division.number,
      house: division.australian_house
    }
  end
end

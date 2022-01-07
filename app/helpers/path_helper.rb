# frozen_string_literal: true

module PathHelper
  def division_path_simple(division)
    division_path(division_params(division))
  end

  def division_url_simple(division)
    division_url(division_params(division))
  end

  def history_division_path_simple(division)
    history_division_path(division_params(division))
  end

  def edit_division_path_simple(division)
    edit_division_path(division_params(division))
  end

  def person_path_simple(person)
    member_path_simple(person.latest_member)
  end

  def member_path_simple(member)
    member_path(member_params(member))
  end

  def member_policy_path_simple(member, policy)
    member_policy_path(member_params(member).merge(id: policy.id))
  end

  def member_divisions_path_simple(member)
    member_divisions_path(member_params(member))
  end

  def friends_member_path_simple(member)
    friends_member_path(member_params(member))
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

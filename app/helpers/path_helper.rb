# frozen_string_literal: true

module PathHelper
  def division_path_simple(division)
    division_path(division.url_params)
  end

  def division_url_simple(division, options = {})
    division_url(options.merge(division.url_params))
  end

  def history_division_path_simple(division)
    history_division_path(division.url_params)
  end

  def edit_division_path_simple(division)
    edit_division_path(division.url_params)
  end

  def person_path_simple(person)
    member_path_simple(person.latest_member)
  end

  def person_policy_path_simple(person, policy)
    member_policy_path_simple(person.latest_member, policy)
  end

  def card_person_policy_url(person, policy)
    "#{root_url}cards#{person_policy_path_simple(person, policy)}.png"
  end

  def card_member_url(member, cardtype)
    case cardtype
    when nil
      "#{root_url}cards#{member_path_simple(member)}.png"
    else
      "#{root_url}cards#{member_path_simple(member)}/categories/#{cardtype}.png"
    end
  end

  def card_policy_url(policy, cardtype)
    case cardtype
    when nil
      "#{root_url}cards#{policy_path(policy)}.png"
    else
      "#{root_url}cards#{policy_path(policy)}/categories/#{cardtype}.png"
    end
  end

  def person_policy_url_simple(person, policy, options = {})
    member_policy_url_simple(person.latest_member, policy, options)
  end

  def member_path_simple(member)
    member_path(member.url_params)
  end

  def member_policy_path_simple(member, policy)
    member_policy_path(member.url_params.merge(id: policy.id))
  end

  def member_policy_url_simple(member, policy, options = {})
    member_policy_url(options.merge(member.url_params).merge(id: policy.id))
  end

  def member_divisions_path_simple(member)
    member_divisions_path(member.url_params)
  end

  def friends_member_path_simple(member)
    friends_member_path(member.url_params)
  end

  # TODO: Add ability to compare people in different houses
  def compare_member_path_simple(member1, member2)
    p1 = member1.url_params
    p2 = member2.url_params
    compare_member_path(p1.merge(mpc2: p2[:mpc], mpn2: p2[:mpn]))
  end
end

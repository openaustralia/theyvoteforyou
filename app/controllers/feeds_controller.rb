class FeedsController < ApplicationController
  def mp_info
    # FIXME: We should change the accepted value to senate instead of lords
    house = params[:house] == 'lords' ? 'senate' : 'representatives'
    @members = Member.in_australian_house(house).joins(:member_info).order(:entered_house, :last_name, :first_name, :constituency)
    @most_recent_division = Division.most_recent_date

    @current_members_by_attendance = Ranker.rank(@members.current, by: :attendance_fraction)
    @current_members_count = @members.current.count

    members_with_rebellions = @members.current.to_a.delete_if { |m| !m.rebellions_fraction }
    @current_members_by_rebellions = Ranker.rank(members_with_rebellions, by: :rebellions_fraction)
    @members_with_rebellions_and_party_whip_count = members_with_rebellions.select { |m| m.has_whip? }.count
  end

  def mpdream_info
    @policy = Policy.find(params[:id])

    # TODO: We shouldn't need to run this each time as Rails correctly refreshes this cache
    # when things change: https://github.com/openaustralia/publicwhip/blob/c341d2cc5fc8b4158db856659936cbf6396f7459/app/models/policy.rb#L65
    @policy.calculate_member_agreement_percentages!

    # FIXME: Using SQL to match PHP, see #211 for detailed description
    sql = "select policy_member_distances.person, distance_a, distance_b, members.mp_id as mp_id,
           (nvotessame + nvotessamestrong + nvotesdiffer + nvotesdifferstrong) as both_voted,
           (nvotesabsent + nvotesabsentstrong) as absent
           from policy_member_distances, members
           where dream_id = '#{@policy.id}' and
           members.person = policy_member_distances.person"
    @policy_member_distances = PolicyMemberDistance.connection.select_all(sql)
  end
end

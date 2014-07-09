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
    # FIXME: Using SQL to match PHP, see #211 for detailed description
    sql = "select pw_cache_dreamreal_distance.person, distance_a, distance_b, pw_mp.mp_id as mp_id,
           (nvotessame + nvotessamestrong + nvotesdiffer + nvotesdifferstrong) as both_voted,
           (nvotesabsent + nvotesabsentstrong) as absent
           from pw_cache_dreamreal_distance, pw_mp
           where dream_id = '#{@policy.id}' and
           pw_mp.person = pw_cache_dreamreal_distance.person"
    @policy_member_distances = PolicyMemberDistance.connection.select_all(sql)
  end
end

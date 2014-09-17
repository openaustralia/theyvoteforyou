class FeedsController < ApplicationController
  def mp_info
    @members = Member.in_australian_house(params[:house] || 'representatives').joins(:member_info).order(:entered_house, :last_name, :first_name, :constituency)
    @most_recent_division = Division.most_recent_date

    @current_members_by_attendance = Ranker.rank(@members.current, by: lambda{|m| m.person.attendance_fraction})
    @current_members_count = @members.current.count

    members_with_rebellions = @members.current.to_a.delete_if { |m| !m.person.rebellions_fraction }
    @current_members_by_rebellions = Ranker.rank(members_with_rebellions, by: lambda {|m| m.person.rebellions_fraction})
    @members_with_rebellions_and_party_whip_count = members_with_rebellions.select { |m| m.has_whip? }.count
  end

  def mpdream_info
    @policy = Policy.find(params[:id])

    # TODO: We shouldn't need to run this each time as Rails correctly refreshes this cache
    # when things change: https://github.com/openaustralia/publicwhip/blob/c341d2cc5fc8b4158db856659936cbf6396f7459/app/models/policy.rb#L65
    @policy.calculate_member_distances!

    # FIXME: Using SQL to match PHP, see #211 for detailed description
    sql = "select policy_person_distances.person_id, distance_a, distance_b, members.id as member_id,
           (nvotessame + nvotessamestrong + nvotesdiffer + nvotesdifferstrong) as both_voted,
           (nvotesabsent + nvotesabsentstrong) as absent
           from policy_person_distances, members
           where policy_id = '#{@policy.id}' and
           members.person_id = policy_person_distances.person_id"
    @policy_person_distances = PolicyPersonDistance.connection.select_all(sql)
  end
end

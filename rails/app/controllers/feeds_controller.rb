class FeedsController < ApplicationController
  def mp_info
    # FIXME: We should change the accepted value to senate instead of lords
    house =  params[:house] == 'lords' ? 'senate' : 'representatives'
    @members = Member.in_australian_house(house).joins(:member_info).order(:entered_house, :last_name, :first_name, :constituency)
    @most_recent_division = Division.most_recent_date

    @current_members_by_attendance = @members.current.sort_by { |m| m.attendance_fraction }
    @current_members_count = @members.current.count
    @current_members_by_rebellions = @members.current.to_a.delete_if { |m| !m.rebellions_fraction }.sort_by { |m| m.rebellions_fraction }
    @current_members_with_party_whip_count = @members.current.select { |m| m.has_whip? }.count
  end

  def mpdream_info
    @policy_member_distances = PolicyMemberDistance.where(dream_id: params[:id])
  end
end

xml.instruct! :xml, version: "1.0", encoding: "ISO-8859-1"
xml.publicwhip do
  @members.each do |member|
    memberinfo = {id: "uk.org.publicwhip/member/#{member.id}",
                  public_whip_data_date: (member.left_house >= @most_recent_division ? @most_recent_division : "complete"),
                  public_whip_division_attendance: fraction_to_percentage_display(member.attendance_fraction, precision: 2),
                  public_whip_rebellions: fraction_to_percentage_display(member.rebellions_fraction, precision: 2)}
    if member.currently_in_parliament?
      # This is wrong because you can have equal ranking, i.e. Standard Competition Ranking
      memberinfo[:public_whip_attendrank] = @current_members_by_attendance.index(member)
      memberinfo[:public_whip_attendrank_outof] = @current_members_count
      if member.rebellions_fraction
        # This is wrong because you can have equal ranking, i.e. Standard Competition Ranking
        memberinfo[:public_whip_rebelrank] = @current_members_by_rebellions.index(member)
        memberinfo[:public_whip_rebelrank_outof] = @current_members_with_party_whip_count
      end
    end
    xml.memberinfo(memberinfo)
  end
end

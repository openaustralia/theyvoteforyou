xml.instruct! :xml, version: "1.0", encoding: "ISO-8859-1"
xml.publicwhip do
  @members.each do |member|
    memberinfo = { id: "uk.org.publicwhip/member/#{member.id}",
                   public_whip_data_date: (member.left_house >= @most_recent_division ? @most_recent_division : "complete"),
                   public_whip_division_attendance: fraction_to_percentage_display(member.person.attendance_fraction, precision: 2),
                   public_whip_rebellions: fraction_to_percentage_display(member.person.rebellions_fraction, precision: 2) }
    if member.currently_in_parliament?
      memberinfo[:public_whip_attendrank] = @current_members_by_attendance.select { |r| r.rankables.include? member }.first.rank
      memberinfo[:public_whip_attendrank_outof] = @current_members_count
      if member.person.rebellions_fraction
        # This is wrong because you can have equal ranking, i.e. Standard Competition Ranking
        memberinfo[:public_whip_rebelrank] = @current_members_by_rebellions.select { |r| r.rankables.include? member }.first.rank
        memberinfo[:public_whip_rebelrank_outof] = @members_with_rebellions_and_party_whip_count
      end
    end
    xml.memberinfo(memberinfo)
  end
end

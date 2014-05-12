xml.instruct! :xml, version: "1.0", encoding: "ISO-8859-1"
xml.publicwhip do
  @members.each do |member|
    # TODO: public_whip_attendrank & public_whip_rebelrank
    xml.memberinfo(id: "uk.org.publicwhip/member/#{member.id}",
                   public_whip_data_date: (member.left_house >= @most_recent_division ? @most_recent_division : "complete"),
                   public_whip_division_attendance: fraction_to_percentage_display(member.attendance_fraction, precision: 2),
                   public_whip_rebellions: fraction_to_percentage_display(member.rebellions_fraction, precision: 2))
  end
end

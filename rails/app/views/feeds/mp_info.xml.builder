xml.instruct! :xml, version: "1.0", encoding: "ISO-8859-1"
xml.publicwhip do
  @members.each do |member|
    xml.memberinfo(id: member.gid,
                   public_whip_data_date: (member.left_house >= @most_recent_division ? @most_recent_division : "complete"),
                   public_whip_division_attendance: "13.90%",
                   public_whip_rebellions: "0.00%")
  end
end

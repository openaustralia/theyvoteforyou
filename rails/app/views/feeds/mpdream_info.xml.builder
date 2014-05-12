xml.instruct! :xml, version: "1.0", encoding: "ISO-8859-1"
xml.publicwhip do
  @policy_member_distances.each do |pmd|
    xml.memberinfo("id" => "uk.org.publicwhip/member/#{pmd.member.id}",
                   "public_whip_dreammp#{pmd.policy.id}_distance" => number_with_precision(pmd.distance_a, strip_insignificant_zeros: true),
                   "public_whip_dreammp#{pmd.policy.id}_both_voted" => pmd.nvotessame + pmd.nvotessamestrong + pmd.nvotesdiffer + pmd.nvotesdifferstrong,
                   "public_whip_dreammp#{pmd.policy.id}_absent" => pmd.nvotesabsent + pmd.nvotesabsentstrong)
  end
end

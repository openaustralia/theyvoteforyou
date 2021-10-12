# frozen_string_literal: true

xml.instruct! :xml, version: "1.0", encoding: "ISO-8859-1"
xml.publicwhip do
  @policy_person_distances.each do |pmd|
    xml.memberinfo("id" => "uk.org.publicwhip/member/#{pmd['member_id']}",
                   "public_whip_dreammp#{@policy.id}_distance" => number_with_precision(pmd["distance_a"], precision: 99, strip_insignificant_zeros: true),
                   "public_whip_dreammp#{@policy.id}_both_voted" => pmd["both_voted"],
                   "public_whip_dreammp#{@policy.id}_absent" => pmd["absent"])
  end
end

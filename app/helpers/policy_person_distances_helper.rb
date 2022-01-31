# frozen_string_literal: true

module PolicyPersonDistancesHelper
  # Returns things like "voted strongly against", "has never voted on", etc..
  def policy_agreement_summary(policy_person_distance, with_person: false, link_person: false, with_policy: false, link_policy: false)
    member = policy_person_distance.person.latest_member
    policy = policy_person_distance.policy
    category_words_sentence(
      policy_person_distance.category(current_user),
      person: (link_to_if(link_person, member.name, member_path_simple(member)) if with_person),
      policy: (link_to_if(link_policy, policy.name, policy) if with_policy)
    )
  end

  # This helper has to just concern itself with getting the correct wording and order for a particular category
  def category_words_sentence(category, person: nil, policy: nil)
    out = []
    if category == :not_enough
      # For this category we have to order the sentence differently because it doesn't have the
      # same structure as the other sentences
      # Note that we're capitalising the first letter
      out << "We can't say anything concrete about how ".html_safe
      out << (person || "they")
      out << " voted on"
    else
      if person
        out << person
        out << " "
      end
      out << case category
             when :for3 then "voted consistently for"
             when :for2 then "voted almost always for"
             when :for1 then "voted generally for"
             when :mixture then "voted a mixture of for and against"
             when :against1 then "voted generally against"
             when :against2 then "voted almost always against"
             when :against3 then "voted consistently against"
             when :never then "has never voted on"
             else
               raise "Unsupported category #{category}"
             end
    end

    if policy
      out << " "
      out << policy
    end
    safe_join(out)
  end
end

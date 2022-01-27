# frozen_string_literal: true

module PolicyPersonDistancesHelper
  # Returns things like "voted strongly against", "has never voted on", etc..
  def policy_agreement_summary(policy_person_distance, with_person: false)
    out = []
    if with_person
      out << policy_person_distance.person.name
      out << " "
    end
    out << category_words(policy_person_distance.category(current_user))
    safe_join(out)
  end

  def category_words(category)
    case category
    when :for3 then "voted consistently for"
    when :for2 then "voted almost always for"
    when :for1 then "voted generally for"
    when :mixture then "voted a mixture of for and against"
    when :against1 then "voted generally against"
    when :against2 then "voted almost always against"
    when :against3 then "voted consistently against"
    when :never then "has never voted on"
    when :not_enough then "has not voted enough to determine a position on"
    else
      raise "Unsupported category #{category}"
    end
  end
end

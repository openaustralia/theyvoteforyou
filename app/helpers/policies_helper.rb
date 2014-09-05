module PoliciesHelper
  def policies_list_sentence(policies)
    policies.map do |policy|
      text = link_to h(policy.name), policy
      text += " ".html_safe + content_tag(:i, "(provisional)") if policy.provisional?
      text
    end.to_sentence.html_safe
  end

  # Returns things like "voted strongly against", "has never voted on", etc..
  def policy_agreement_summary(policy, person)
    if person.number_of_votes_on_policy(policy) == 0
      "has <em>never voted</em> on".html_safe
    else
      fraction = person.agreement_fraction_with_policy(policy)
      if fraction >= 0.80
        "voted <em>strongly for</em>".html_safe
      elsif fraction >= 0.60
        "voted <em>moderately for</em>".html_safe
      elsif fraction <= 0.20
        "voted <em>strongly against</em>".html_safe
      elsif fraction <= 0.40
        "voted <em>moderately against</em>".html_safe
      else
        "voted <em>ambiguously</em> on".html_safe
      end
    end
  end
end

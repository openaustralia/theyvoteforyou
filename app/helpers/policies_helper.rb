module PoliciesHelper
  def policies_list_sentence(policies)
    policies.map do |policy|
      text = link_to h(policy.name), policy
      text += " ".html_safe + content_tag(:i, "(provisional)") if policy.provisional?
      text
    end.to_sentence.html_safe
  end

  # Returns things like "voted strongly against", "has never voted on", etc..
  def policy_agreement_summary(number_of_votes_on_policy, agreement_fraction_with_policy)
    if number_of_votes_on_policy == 0
      "has <em>never voted</em> on".html_safe
    elsif agreement_fraction_with_policy >= 0.80
      "voted <em>strongly for</em>".html_safe
    elsif agreement_fraction_with_policy >= 0.60
      "voted <em>moderately for</em>".html_safe
    elsif agreement_fraction_with_policy <= 0.20
      "voted <em>strongly against</em>".html_safe
    elsif agreement_fraction_with_policy <= 0.40
      "voted <em>moderately against</em>".html_safe
    else
      "voted <em>ambiguously</em> on".html_safe
    end
  end
end

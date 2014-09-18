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

  def quote(word)
    "&ldquo;" + word + "&rdquo;"
  end

  def policy_version_sentence(version)
    if version.event == "create"
      name = version.changeset["name"].second
      description = version.changeset["description"].second
      result = "Created"
      result += version.changeset["private"].second == 2 ? " provisional " : " "
      result += "policy " + quote(name) + " with description " + quote(description)
    elsif version.event == "update"
      changes = []
      if version.changeset.has_key?("name")
        name1 = version.changeset["name"].first
        name2 = version.changeset["name"].second
        changes << "name from " + quote(name1) + " to " + quote(name2)
      end
      if version.changeset.has_key?("description")
        description1 = version.changeset["description"].first
        description2 = version.changeset["description"].second
        changes << "description from " + quote(description1) + " to " + quote(description2)
      end
      if version.changeset.has_key?("private")
        if version.changeset["private"].second == 0
          changes << "status to not provisional"
        elsif version.changeset["private"].second == 2
          changes << "status to provisional"
        else
          raise
        end
      end
      result = "Changed " + changes.to_sentence
    else
      raise
    end
    result
  end

  def policy_division_version_vote(version)
    if version.event == "create"
      version.changeset["vote"].second
    elsif version.event == "destroy"
      version.reify.vote
    elsif version.event == "update"
      version.changeset["vote"].first + " to " + version.changeset["vote"].second
    end
  end

  def policy_division_version_division(version)
    id = version.event == "create" ? version.changeset["division_id"].second : version.reify.division_id
    Division.find(id)
  end

  def policy_division_version_sentence(version)
    actions = {"create" => "Added", "destroy" => "Removed", "update" => "Changed"}

    vote = policy_division_version_vote(version)
    division = policy_division_version_division(version)
    actions[version.event] + " " + vote + " vote on division " + division.name
  end

  def version_attribution_sentence(version)
    user_name = User.find(version.whodunnit).real_name
    time = time_ago_in_words(version.created_at)
    "by " + user_name + ", " + time + " ago"
  end

  def version_sentence(version)
    if version.item_type == "Policy"
      result = policy_version_sentence(version)
    elsif version.item_type == "PolicyDivision"
      result = policy_division_version_sentence(version)
    end
    result += " " + version_attribution_sentence(version)
    result
  end
end

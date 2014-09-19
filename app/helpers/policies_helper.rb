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
      case person.agreement_fraction_with_policy(policy)
      when 0.95..1.0
        "voted <em>very strongly for</em>".html_safe
      when 0.85...0.95
        "voted <em>strongly for</em>".html_safe
      when 0.60...0.85
        "voted <em>moderately for</em>".html_safe
      when 0.40...0.60
        "voted <em>a mixture of for and against</em> on".html_safe
      when 0.15...0.40
        "voted <em>moderately against</em>".html_safe
      when 0.05...0.15
        "voted <em>strongly against</em>".html_safe
      when 0.00...0.05
        "voted <em>very strongly against</em>".html_safe
      else
        "voted <em>unknown about</em".html_safe
      end
    end
  end

  def quote(word)
    ("&ldquo;" + h(word) + "&rdquo;").html_safe
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
    result.html_safe
  end

  def policy_division_version_vote(version)
    if version.event == "create"
      content_tag(:strong, vote_display_in_table(version.changeset["vote"].second).downcase)
    elsif version.event == "destroy"
      content_tag(:strong, vote_display_in_table(version.reify.vote).downcase)
    elsif version.event == "update"
      content_tag(:strong, vote_display_in_table(version.changeset["vote"].first).downcase) + " to ".html_safe + content_tag(:strong, vote_display_in_table(version.changeset["vote"].second).downcase)
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
    actions[version.event].html_safe + " ".html_safe + vote + " on ".html_safe + link_to(division.name, division_path2(division))
  end

  def version_attribution_sentence(version)
    user = User.find(version.whodunnit)
    time = time_ago_in_words(version.created_at)
    ("by " + link_to(user.real_name, user) + ", " + time + " ago").html_safe
  end

  def version_sentence(version)
    if version.item_type == "Policy"
      result = policy_version_sentence(version)
    elsif version.item_type == "PolicyDivision"
      result = policy_division_version_sentence(version)
    end
    result += " ".html_safe + version_attribution_sentence(version)
    result
  end
end

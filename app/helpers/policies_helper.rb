module PoliciesHelper
  def policies_list_sentence(policies)
    policies.map do |policy|
      text = link_to h(policy.name), policy
      text += " ".html_safe + content_tag(:i, "(draft)") if policy.provisional?
      text
    end.to_sentence.html_safe
  end

  def policy_agreement_summary_without_html(policy_member_distance)
    policy_agreement_summary(policy_member_distance).gsub("<strong>", "").gsub("</strong>", "")
  end

  # Returns things like "voted strongly against", "has never voted on", etc..
  def policy_agreement_summary(policy_member_distance)
    if policy_member_distance.nil?
      "voted <strong>unknown about</strong>".html_safe
    elsif policy_member_distance.number_of_votes == 0
      "has <strong>never voted</strong> on".html_safe
    else
      text = ranges.find{|r| r.first.include?(policy_member_distance.agreement_fraction)}.second
      "voted ".html_safe + content_tag(:strong, text.html_safe)
    end
  end

  # TODO This shouldn't really be in a helper should it? It smells a lot like "business" logic
  def ranges
    {
      0.95..1.00 => "very strongly for",
      0.85..0.95 => "strongly for",
      0.60..0.85 => "moderately for",
      0.40..0.60 => "a mixture of for and against",
      0.15..0.40 => "moderately against",
      0.05..0.15 => "strongly against",
      0.00..0.05 => "very strongly against"
    }
  end

  def quote(word)
    "“#{word}”"
  end

  def policy_version_sentence(version, options)
    if version.event == "create"
      name = version.changeset["name"].second
      description = version.changeset["description"].second
      result = "Created"
      result += version.changeset["private"].second == 2 ? " draft " : " "
      if options[:show_policy]
        policy = Policy.find(version.changeset["id"].second)
        result += "policy " + link_to(quote(name), policy) + " with description " + quote(description)
      else
        result += "policy " + quote(name) + " with description " + quote(description)
      end
    elsif version.event == "update"
      changes = []
      if version.changeset.has_key?("name")
        name1 = version.changeset["name"].first
        name2 = version.changeset["name"].second
        if options[:show_policy]
          changes << "name to " + quote(name2)
        else
          changes << "name from " + quote(name1) + " to " + quote(name2)
        end
      end
      if version.changeset.has_key?("description")
        description1 = version.changeset["description"].first
        description2 = version.changeset["description"].second
        changes << "description from " + quote(description1) + " to " + quote(description2)
      end
      if version.changeset.has_key?("private")
        if version.changeset["private"].second == 0
          changes << "status to not draft"
        elsif version.changeset["private"].second == 2
          changes << "status to draft"
        else
          raise
        end
      end
      if options[:show_policy]
        policy = version.reify
        result = "On policy " + link_to(policy.name, policy) + " changed " + changes.to_sentence
      else
        result = "Changed " + changes.to_sentence
      end
    else
      raise
    end
    result.html_safe
  end

  def policy_version_multiple_paragraphs(version, options)
    if version.event == "create"
      name = version.changeset["name"].second
      description = version.changeset["description"].second
      result = "Created"
      result += version.changeset["private"].second == 2 ? " draft " : " "
      if options[:show_policy]
        policy = Policy.find(version.changeset["id"].second)
        result += "policy " + link_to(quote(name), policy) + " with description " + quote(description)
      else
        result += "policy " + quote(name) + " with description " + quote(description)
      end
    elsif version.event == "update"
      changes = []
      if version.changeset.has_key?("name")
        name1 = version.changeset["name"].first
        name2 = version.changeset["name"].second
        if options[:show_policy]
          changes << "name to " + quote(name2)
        else
          changes << "name from " + quote(name1) + " to " + quote(name2)
        end
      end
      if version.changeset.has_key?("description")
        description1 = version.changeset["description"].first
        description2 = version.changeset["description"].second
        changes << "description from " + quote(description1) + " to " + quote(description2)
      end
      if version.changeset.has_key?("private")
        if version.changeset["private"].second == 0
          changes << "status to not draft"
        elsif version.changeset["private"].second == 2
          changes << "status to draft"
        else
          raise
        end
      end
      if options[:show_policy]
        policy = version.reify

        result = changes.map do |change|
          content_tag(:p, "On policy " + link_to(policy.name, policy) + " changed " + change.to_s + ".")
        end.join
      else
        result = changes.map do |change|
          content_tag(:p, "Changed " + change + ".")
        end.join
      end
    else
      raise
    end
    result.html_safe
  end

  def policy_division_version_vote(version)
    if version.event == "create"
      vote_display(version.changeset["vote"].second)
    elsif version.event == "destroy"
      vote_display(version.reify.vote)
    elsif version.event == "update"
      vote_display(version.changeset["vote"].first) + " to ".html_safe + vote_display(version.changeset["vote"].second)
    end
  end

  def policy_division_version_division(version)
    id = version.event == "create" ? version.changeset["division_id"].second : version.reify.division_id
    Division.find(id)
  end

  def policy_division_version_sentence(version, options)
    actions = {"create" => "Added", "destroy" => "Removed", "update" => "Changed"}

    vote = policy_division_version_vote(version)
    division = policy_division_version_division(version)
    if options[:show_policy]
      policy = Policy.find(version.policy_id)
      "On policy ".html_safe + link_to(policy.name, policy) + " ".html_safe + actions[version.event].downcase.html_safe + " ".html_safe + vote + " on ".html_safe + link_to(division.name, division)
    else
      actions[version.event].html_safe + " ".html_safe + vote + " on ".html_safe + link_to(division.name, division)
    end
  end

  def policy_division_version_sentence2(version, options)
    actions = {"create" => "Connected", "destroy" => "Disconnected", "update" => "Changed"}
    vote = policy_division_version_vote(version)
    division = policy_division_version_division(version)

    if options[:show_policy]
      policy = Policy.find(version.policy_id)
      "On policy ".html_safe + link_to(policy.name, policy) + ": ".html_safe + actions[version.event].downcase.html_safe + " ".html_safe + vote + " on ".html_safe + link_to(division.name, division)
    else
      if version.event == "update"
        actions[version.event].html_safe + " vote from ".html_safe + vote + " on division ".html_safe + content_tag(:em, link_to(division.name, division)) + ".".html_safe
      elsif version.event == "create" || version.event == "destroy"
        if version.event == "create"
          tense = " set to "
        else
          tense = " was "
        end
        actions[version.event].html_safe + " division ".html_safe + content_tag(:em, link_to(division.name, division)) + ". Policy vote ".html_safe + tense + vote + ".".html_safe
      else
        raise
      end
    end
  end

  def version_attribution_sentence(version)
    user = User.find(version.whodunnit)
    time = time_ago_in_words(version.created_at)
    ("by " + link_to(user.name, user) + ", " + time + " ago").html_safe
  end

  def version_sentence(version, options = {})
    if version.item_type == "Policy"
      result = policy_version_sentence(version, options)
    elsif version.item_type == "PolicyDivision"
      result = policy_division_version_sentence(version, options)
    end
    result += " ".html_safe + version_attribution_sentence(version)
    result
  end

  def version_sentence_no_attribution(version, options = {})
    if version.item_type == "Policy"
      result =  policy_version_multiple_paragraphs(version, options)
    elsif version.item_type == "PolicyDivision"
      result = content_tag(:p, policy_division_version_sentence2(version, options))
    end
    result
  end

  def version_author_link(version)
    user = User.find(version.whodunnit)
    link_to(user.name, user)
  end

  def capitalise_initial_character(text)
    text[0].upcase + text[1..-1]
  end
end

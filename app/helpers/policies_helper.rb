# frozen_string_literal: true

module PoliciesHelper
  def policies_list_sentence(policies)
    policies.map do |policy|
      text = link_to h(policy.name), policy
      text += " ".html_safe + content_tag(:i, "(draft)") if policy.provisional?
      text
    end.to_sentence.html_safe
  end

  def policy_agreement_summary_without_html(policy_member_distance)
    policy_agreement_summary_first_word(policy_member_distance) +
      " ".html_safe +
      policy_agreement_summary_short(policy_member_distance)
  end

  # Returns things like "voted strongly against", "has never voted on", etc..
  def policy_agreement_summary(policy_member_distance)
    policy_agreement_summary_first_word(policy_member_distance) +
      " ".html_safe +
      content_tag(:strong, policy_agreement_summary_short(policy_member_distance))
  end

  def policy_agreement_summary_first_word(policy_member_distance)
    (policy_member_distance&.number_of_votes&.zero? ? "has" : "voted").html_safe
  end

  def policy_agreement_summary_short(policy_member_distance)
    text = if policy_member_distance.nil?
             "unknown about"
           elsif policy_member_distance.number_of_votes.zero?
             "never voted on"
           else
             ranges.find { |r| r.first.include?(policy_member_distance.agreement_fraction) }.second
           end
    text.html_safe
  end

  # TODO: This shouldn't really be in a helper should it? It smells a lot like "business" logic
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

  def policy_version_sentence(version, _options)
    case version.event
    when "create"
      name = version.changeset["name"].second
      description = version.changeset["description"].second
      result = "Created"
      result += version.changeset["private"].second == 2 ? " draft " : " "
      result += "policy #{quote(name)} with description #{quote(description)}"
      result = content_tag(:p, "#{result}.", class: "change-action")
    when "update"
      changes = []

      if version.changeset.key?("name")
        name1 = version.changeset["name"].first
        name2 = version.changeset["name"].second
        changes << "Name changed from #{quote(name1)} to #{quote(name2)}"
      end

      if version.changeset.key?("description")
        description1 = version.changeset["description"].first
        description2 = version.changeset["description"].second
        changes << "Description changed from #{quote(description1)} to #{quote(description2)}"
      end

      if version.changeset.key?("private")
        case version.changeset["private"].second
        when 0, "published"
          changes << "Changed status to not draft"
        when 2, "provisional"
          changes << "Changed status to draft"
        else
          raise "Unexpected value for private: #{version.changeset['private'].second}"
        end
      end

      result = changes.map do |change|
        content_tag(:p, "#{change}.", class: "change-action")
      end.join
    else
      raise
    end
    result.html_safe
  end

  def policy_version_sentence_text(version)
    case version.event
    when "create"
      name = version.changeset["name"].second
      description = version.changeset["description"].second
      result = "Created"
      result += version.changeset["private"].second == 2 ? " draft " : " "
      result += "policy #{quote(name)} with description #{quote(description)}"
      result += "."
    when "update"
      changes = []

      if version.changeset.key?("name")
        name1 = version.changeset["name"].first
        name2 = version.changeset["name"].second
        changes << "name from #{quote(name1)} to #{quote(name2)}"
      end

      if version.changeset.key?("description")
        description1 = version.changeset["description"].first
        description2 = version.changeset["description"].second
        changes << "description from #{quote(description1)} to #{quote(description2)}"
      end

      if version.changeset.key?("private")
        case version.changeset["private"].second
        when 0
          changes << "status to not draft"
        when 2
          changes << "status to draft"
        else
          raise
        end
      end

      result = changes.map do |change|
        "* Changed #{change}."
      end.join("\n")
    else
      raise
    end
    result
  end

  def policy_division_version_vote(version)
    case version.event
    when "create"
      policy_vote_display_with_class(version.changeset["vote"].second)
    when "destroy"
      policy_vote_display_with_class(version.reify.vote)
    when "update"
      text = policy_vote_display_with_class(version.changeset["vote"].first)
      text += " to ".html_safe
      text += policy_vote_display_with_class(version.changeset["vote"].second)
      text
    end
  end

  def policy_division_version_vote_text(version)
    case version.event
    when "create"
      vote_display(version.changeset["vote"].second)
    when "destroy"
      vote_display(version.reify.vote)
    when "update"
      "#{vote_display(version.changeset['vote'].first)} to #{vote_display(version.changeset['vote'].second)}"
    end
  end

  def policy_division_version_division(version)
    id = version.event == "create" ? version.changeset["division_id"].second : version.reify.division_id
    Division.find(id)
  end

  def policy_division_version_sentence(version, options)
    actions = { "create" => "Added", "destroy" => "Removed", "update" => "Changed" }
    vote = policy_division_version_vote(version)
    division = policy_division_version_division(version)

    case version.event
    when "update"
      actions[version.event].html_safe + " vote from ".html_safe + vote + " on division ".html_safe + content_tag(:em, link_to(division.name, division_path(division, options))) + ".".html_safe
    when "create", "destroy"
      tense = if version.event == "create"
                "set to "
              else
                "was "
              end
      actions[version.event].html_safe + " division ".html_safe + content_tag(:em, link_to(division.name, division_path(division, options))) + ". Policy vote ".html_safe + tense + vote + ".".html_safe
    else
      raise
    end
  end

  def policy_division_version_sentence_text(version, options)
    actions = { "create" => "Added", "destroy" => "Removed", "update" => "Changed" }
    vote = policy_division_version_vote_text(version)
    division = policy_division_version_division(version)

    case version.event
    when "update"
      "#{actions[version.event]} vote from #{vote} on division #{division.name}.\n#{division_path(division, options)}"
    when "create", "destroy"
      tense = if version.event == "create"
                "set to "
              else
                "was "
              end
      "#{actions[version.event]} division #{division.name}. Policy vote #{tense}#{vote}.\n#{division_path(division, options)}"
    else
      raise
    end
  end

  def version_policy(version)
    Policy.find(version.policy_id)
  end

  def version_attribution_sentence(version)
    user = User.find(version.whodunnit)
    time = time_ago_in_words(version.created_at)
    "by #{link_to(user.name, user)}, #{time} ago".html_safe
  end

  def version_sentence(version, options = {})
    case version.item_type
    when "Policy"
      policy_version_sentence(version, options)
    when "PolicyDivision"
      content_tag(:p, policy_division_version_sentence(version, options), class: "change-action")
    end
  end

  def version_sentence_text(version, options = {})
    case version.item_type
    when "Policy"
      policy_version_sentence_text(version)
    when "PolicyDivision"
      policy_division_version_sentence_text(version, options)
    end
  end

  def version_author_link(version, options = {})
    if version.is_a?(WikiMotion)
      link_to version.user.name, user_path(version.user, options)
    else
      user = User.find(version.whodunnit)
      link_to user.name, user_url(user, options)
    end
  end

  def version_attribution_text(version)
    if version.is_a?(WikiMotion)
      "By #{version.user.name} at #{@version.created_at.strftime('%I:%M%p - %d %b %Y')}\n#{user_path(version.user, only_path: false)}"
    else
      user = User.find(version.whodunnit)
      "By #{user.name} at #{@version.created_at.strftime('%I:%M%p - %d %b %Y')}\n#{user_url(user, only_path: false)}"
    end
  end

  def capitalise_initial_character(text)
    text[0].upcase + text[1..-1]
  end
end

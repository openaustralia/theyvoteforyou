# frozen_string_literal: true

module PoliciesHelper
  # Returns things like "voted strongly against", "has never voted on", etc..
  def policy_agreement_summary(policy_person_distance)
    out = []
    out << policy_agreement_summary_first_word(policy_person_distance)
    out << " "
    out << policy_agreement_summary_short(policy_person_distance)
    safe_join(out)
  end

  def policy_agreement_summary_first_word(policy_person_distance)
    policy_person_distance&.number_of_votes&.zero? ? "has" : "voted"
  end

  def policy_agreement_summary_short(policy_person_distance)
    if policy_person_distance.nil?
      "unknown about"
    elsif policy_person_distance.number_of_votes.zero?
      "never voted on"
    else
      ranges3[category(policy_person_distance)]
    end
  end

  def category(policy_person_distance)
    return :never if policy_person_distance.number_of_votes.zero?

    ranges2.find { |r| r[:range].include?(policy_person_distance.agreement_fraction) }[:category]
  end

  # TODO: This shouldn't really be in a helper should it? It smells a lot like "business" logic
  def ranges2
    [
      { range: 0.95..1.00, category: :for3 },
      { range: 0.85..0.95, category: :for2 },
      { range: 0.60..0.85, category: :for1 },
      { range: 0.40..0.60, category: :mixture },
      { range: 0.15..0.40, category: :against1 },
      { range: 0.05..0.15, category: :against2 },
      { range: 0.00..0.05, category: :against3 }
    ]
  end

  def ranges3
    {
      for3: "consistently for",
      for2: "almost always for",
      for1: "generally for",
      mixture: "a mixture of for and against",
      against1: "generally against",
      against2: "almost always against",
      against3: "consistently against"
    }
  end

  def quote(word)
    "“#{word}”"
  end

  def policy_version_sentence(version, _options)
    changes = []

    case version.event
    when "create"
      name = version.changeset["name"].second
      description = version.changeset["description"].second
      result = "Created"
      result += version.changeset["private"].second == 2 ? " draft " : " "
      result += "policy #{quote(name)} with description #{quote(description)}."
      changes << result
    when "update"
      if version.changeset.key?("name")
        name1 = version.changeset["name"].first
        name2 = version.changeset["name"].second
        changes << "Name changed from #{quote(name1)} to #{quote(name2)}."
      end

      if version.changeset.key?("description")
        description1 = version.changeset["description"].first
        description2 = version.changeset["description"].second
        changes << "Description changed from #{quote(description1)} to #{quote(description2)}."
      end

      if version.changeset.key?("private")
        case version.changeset["private"].second
        when 0, "published"
          changes << "Changed status to not draft."
        when 2, "provisional"
          changes << "Changed status to draft."
        else
          raise "Unexpected value for private: #{version.changeset['private'].second}"
        end
      end
    else
      raise
    end

    safe_join(changes.map { |change| content_tag(:p, change, class: "change-action") })
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
        when 0, "published"
          changes << "status to not draft"
        when 2, "provisional"
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
    vote = policy_division_version_vote(version)
    division = policy_division_version_division(version)
    division_link = content_tag(:em, link_to(division.name, division_path(division, options)))
    out = []

    case version.event
    when "update"
      out << "Changed vote from "
      out << vote
      out << " on division "
      out << division_link
    when "create"
      out = []
      out << "Added division "
      out << division_link
      out << ". Policy vote set to "
      out << vote
    when "destroy"
      out = []
      out << "Removed division "
      out << division_link
      out << ". Policy vote was "
      out << vote
    else
      raise
    end

    out << "."
    safe_join(out)
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
    out = []
    out << "by "
    out << link_to(user.name, user)
    out << ", #{time_ago_in_words(version.created_at)} ago"
    safe_join(out)
  end

  # TODO: Remove duplication between version_sentence and version_sentence_text and methods they call
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

  def version_author(version)
    if version.is_a?(WikiMotion)
      version.user
    else
      User.find(version.whodunnit)
    end
  end

  def version_author_link(version, options = {})
    user = version_author(version)
    link_to user.name, user_url(user, options)
  end

  def version_attribution_text(version)
    user = version_author(version)
    "By #{user.name} at #{version.created_at.strftime('%I:%M%p - %d %b %Y')}\n#{user_url(user, only_path: false)}"
  end

  def capitalise_initial_character(text)
    text[0].upcase + text[1..-1]
  end
end

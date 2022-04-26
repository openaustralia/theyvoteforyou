# frozen_string_literal: true

module MembersHelper
  # Also say "whilst Independent" if they used to be in a different party
  def party_long2(member)
    if member.entered_reason == "changed_party" || member.left_reason == "changed_party"
      "whilst #{member.party_name}"
    else
      member.party_name
    end
  end

  def vote_class(vote)
    if vote&.rebellion?
      "rebel"
    else
      ""
    end
  end

  def member_party_type_place_name(member)
    result = "#{member.party_name} #{member.role} #{member.name}"

    member.currently_in_parliament? ? result : "Former #{result}"
  end

  def member_type_party_place_sentence(member)
    # TODO: if not a senator, add the state after the electorate. e.g. Goldstein, Vic
    if member.currently_in_parliament?
      member_type_party_place_sentence_without_former(member)
    else
      safe_join(["Former ", member_type_party_place_sentence_without_former(member)])
    end
  end

  def member_type_party_place_sentence_without_former(member)
    out = []
    out << content_tag(:span, member.party_name, class: "org")
    out << " "
    out << content_tag(:span, member_type_electorate_sentence(member), class: "title")
    safe_join(out)
  end

  # Returns "Representative for Higgins" or "Senator for Tasmania"
  def member_type_electorate_sentence(member)
    out = []
    out << "#{member_type(member.house)} for "
    out << content_tag(:span, member.electorate, class: "electorate")
    safe_join(out)
  end

  def member_history_sentence(member)
    out = []
    out << "Before being "
    out << member_type_party_place_sentence_without_former(member)
    out << ", #{member.name} was "
    # TODO: This looks like it assumes the member is the most recent one. Is that always the case?
    t = member.person.members.order(entered_house: :desc).offset(1).map do |member2, _i|
      out2 = []
      out2 << "#{member2.party_name} "
      out2 << member_type_electorate_sentence(member2)
      safe_join(out2)
    end
    out << to_sentence(t)
    out << "."
    safe_join(out)
  end

  def member_rebellion_record_sentence(member)
    if member.person.rebellions_fraction.zero?
      member.currently_in_parliament? ? "Never rebels" : "Never rebelled"
    else
      # TODO: Should this be an absolute count rather than percentage?
      # Maybe it's good to show it as a percentage because it highlights rarity?
      rebel_text = member.currently_in_parliament? ? "Rebels" : "Rebelled"
      percentage = fraction_to_percentage_display(member.person.rebellions_fraction)
      "#{rebel_text} #{percentage} of the time"
    end
  end

  # Use helper member_image below instead of this one directly
  def small_member_image(member, options = {})
    options = { size: member.small_image_size }.merge(options)
    image_tag(member.small_image_url, options) if member.show_small_image?
  end

  # Use helper member_image below instead of this one directly
  def large_member_image(member, options = {})
    options = { size: member.large_image_size }.merge(options)
    if member.show_large_image?
      image_tag(member.large_image_url, options)
    else
      small_member_image(member, options)
    end
  end

  # Use helper member_image below instead of this one directly
  def extra_large_member_image(member, options = {})
    options = { size: member.extra_large_image_size }.merge(options)
    if member.show_extra_large_image?
      image_tag(member.extra_large_image_url, options)
    else
      large_member_image(member, options)
    end
  end

  # size can be one of :small, :large, :extra_large
  def member_image(member, size, options = {})
    case size
    when :small
      small_member_image(member, options)
    when :large
      large_member_image(member, options)
    when :extra_large
      extra_large_member_image(member, options)
    else
      raise "Unexpected size #{size}"
    end
  end

  def policies_under_category(member, category)
    distances = member.person.policy_person_distances.published
    policies = []
    distances.each do |d|
      if d.category.to_s == category
        Rails.logger.debug Policy.find(d.policy_id)
        policies << Policy.find(d.policy_id)
      end
    end
    policies
  end

  def card_title_from_category(member, category)
    case category.to_sym
    when :not_enough
      "We can't say anything concrete about how #{member.name} voted on"
    else
      "#{member.name} #{category_words_sentence(category.to_sym)}"
    end
  end

  def member_policy_category(member, category, max_policies:)
    policies = policies_under_category(member, category)
    chosen_policies = policies[0..(max_policies - 1)]
    card_title = card_title_from_category(member, category)
    [card_title, chosen_policies, policies.length - chosen_policies.length]
  end
end

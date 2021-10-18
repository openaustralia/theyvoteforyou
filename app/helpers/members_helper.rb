# frozen_string_literal: true

module MembersHelper
  # Also say "whilst Independent" if they used to be in a different party
  def party_long2(member)
    result = if member.entered_reason == "changed_party" || member.left_reason == "changed_party"
               "whilst ".html_safe
             else
               "".html_safe
             end
    result += member.party_name.html_safe
    result
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
      content_tag(:span, "Former #{member.party_name} #{member_type(member.house)} for #{content_tag(:span, member.electorate, class: 'electorate')}".html_safe, class: "title")
    end.html_safe
  end

  def member_type_party_place_sentence_without_former(member)
    text = content_tag(:span, member.party_name, class: "org")
    text += " "
    text += content_tag(:span, "#{member_type(member.house)} for #{content_tag(:span, member.electorate, class: 'electorate')}".html_safe, class: "title")
    text
  end

  def member_type_party_place_date_sentence(member)
    text = member_type_party_place_sentence(member)
    text += " "
    text += if member.currently_in_parliament?
              content_tag(:span, "since #{member.since}", class: "member-period").html_safe
            else
              content_tag(:span, "#{member.since} – #{member.until}", class: "member-period").html_safe
            end
    text
  end

  def member_history_sentence(member)
    text = "Before being #{member_type_party_place_sentence_without_former(member)}, #{member.name_without_title} was "
    # TODO: This looks like it assumes the member is the most recent one. Is that always the case?
    text += member.person.members.order(entered_house: :desc).offset(1).map do |member2, _i|
      s = "#{member2.party_name} #{member_type(member2.house)} for "
      s += content_tag(:span, member2.electorate, class: "electorate")
      s
    end.to_sentence
    text = text.html_safe
    text += "."
    text
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
end

# frozen_string_literal: true

module MembersHelper
  # Also say "whilst Independent" if they used to be in a different party
  def party_long2(member)
    result = if member.entered_reason == "changed_party" || member.left_reason == "changed_party"
               "whilst ".html_safe
             else
               "".html_safe
             end
    result += link_to member.party_name, party_divisions_path(member.party_object)
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
    result = member.party_name + " " + member.role + " " + member.name

    member.currently_in_parliament? ? result : "Former " + result
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
    content_tag(:span, member.party_name, class: "org") + " " + content_tag(:span, "#{member_type(member.house)} for #{content_tag(:span, member.electorate, class: 'electorate')}".html_safe, class: "title")
  end

  def member_type_party_place_date_sentence(member)
    text = member_type_party_place_sentence(member)
    text += if member.currently_in_parliament?
              (" " +
                content_tag(:span, "since #{member.since}", class: "member-period")).html_safe
            else
              (" " +
                content_tag(:span, "#{member.since} – #{member.until}", class: "member-period")).html_safe
            end
    text
  end

  def member_history_sentence(member)
    text = "Before being #{member_type_party_place_sentence_without_former(member)}, #{member.name_without_title} was "
    text += member.person.members.order(entered_house: :desc).offset(1).map do |member, _i|
      member.party_name + " " + member_type(member.house) + " for " + content_tag(:span, member.electorate, class: "electorate")
    end.to_sentence
    text.html_safe + "."
  end

  def member_rebellion_record_sentence(member)
    if member.person.rebellions_fraction.zero?
      member.currently_in_parliament? ? "Never rebels" : "Never rebelled"
    else
      # TODO: Should this be an absolute count rather than percentage?
      # Maybe it's good to show it as a percentage because it highlights rarity?
      (member.currently_in_parliament? ? "Rebels " : "Rebelled ") + fraction_to_percentage_display(member.person.rebellions_fraction) + " of the time"
    end
  end
end

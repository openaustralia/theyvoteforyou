module MembersHelper
  # Also say "whilst Independent" if they used to be in a different party
  def party_long2(member)
    if member.entered_reason == "changed_party" || member.left_reason == "changed_party"
      result = "whilst ".html_safe
    else
      result = "".html_safe
    end
    result += link_to member.party_name, party_divisions_path(member.party_object)
    result
  end

  def vote_class(vote)
    if vote.nil?
      ""
    elsif vote.rebellion?
      "rebel"
    else
      ""
    end
  end

  def member_type_party_place_sentence(member)
    # TODO: if not a senator, add the state after the electorate. e.g. Goldstein, Vic
    if member.currently_in_parliament?
      text = member.party_name + " " + member_type(member.australian_house) + " for " +
        content_tag(:span, member.electorate, class: "electorate")
    else
      text = "Former " + member.party_name + " " + member_type(member.australian_house) + " for " +
        content_tag(:span, member.electorate, class: 'electorate')
    end
    text.html_safe
  end

  def member_type_place_sentence(member)
    # TODO: if not a senator, add the state after the electorate. e.g. Goldstein, Vic
    if member.currently_in_parliament?
      text = member_type(member.australian_house) + " for " +
        content_tag(:span, member.electorate, class: "electorate")
    else
      text = "Former " + member_type(member.australian_house) + " for " +
        content_tag(:span, member.electorate, class: 'electorate')
    end
    text.html_safe
  end

  def member_type_party_place_date_sentence(member)
    text = member_type_party_place_sentence(member)
    if member.currently_in_parliament?
      text += (" " +
        content_tag(:span, "since #{member.since}", class: 'member-period')).html_safe
    else
      text += (", " +
        content_tag(:span, "#{member.since} – #{member.until}", class: 'member-period')).html_safe
    end
    text
  end

  def member_history_sentence(member)
    text = "Before being #{member_type_party_place_sentence(member)}, #{member.name_without_title} was "
    member.person.members.order(entered_house: :desc).offset(1).each_with_index do |member, i|
      text += member.party_name + " " + member_type(member.australian_house) + " for " + content_tag(:span, member.electorate, class: 'electorate')
    end.to_sentence
    text += "."
    text.html_safe
  end
end

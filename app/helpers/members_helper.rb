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
      out = []
      out << "Former #{member.party_name} "
      out << member_type_electorate_sentence(member)
      content_tag(:span, safe_join(out), class: "title")
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

  def member_type_party_place_date_sentence(member)
    text = member_type_party_place_sentence(member)
    text += " "
    text += if member.currently_in_parliament?
              content_tag(:span, "since #{member.since}", class: "member-period")
            else
              content_tag(:span, "#{member.since} – #{member.until}", class: "member-period")
            end
    text
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
end

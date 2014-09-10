module MembersHelper
  def member_path2(member, params = {})
    member_path(params.merge({
        mpn: member.url_name,
        mpc: member.url_electorate,
        house: member.australian_house
      }))
  end

  def vote_records_start_date(member)
    # HACK WARNING
    [member.entered_house, Date.new(2006,1,1)].max.strftime('%B %Y')
  end

  def member_until(member)
    member.left_house > Date.today ? 'still in office' : member.left_house.strftime('%B %Y')
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

  def member_type_place_date_sentence(member)
    if member.currently_in_parliament?
      # TODO: if not a senator, add the state after the electorate. e.g. Goldstein, Vic
      type_part = member_type(member.australian_house)
      place_part = content_tag(:span, member.electorate, class: 'electorate')
      date_part = content_tag(:span, "since #{vote_records_start_date(member)}", class: 'member-period')
    else
      # TODO: if not a senator, add the state after the electorate. e.g. Goldstein, Vic
      type_part = "Former #{member_type(member.australian_house)}"
      place_part = content_tag(:span, member.electorate, class: 'electorate') + ','
      date_part = content_tag(:span, "#{vote_records_start_date(member)} – #{member_until(member)}", class: 'member-period')
    end

    "#{type_part} for #{place_part} #{date_part}".html_safe
  end
end

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
    formatted_date([member.entered_house, Date.new(2006,1,1)].max, true)
  end

  def member_until(member)
    member.left_house > Date.today ? 'still in office' : formatted_date(member.left_house, true)
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
end

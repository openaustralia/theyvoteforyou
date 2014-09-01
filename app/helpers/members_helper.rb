module MembersHelper
  def member_path2(member, params = {})
    params2 = params.merge({
        mpn: member.url_name,
        # TODO Seems odd to me the mpc=Senate would expect mpc=Tasmania
        mpc: member.senator? ? "Senate" : member.url_electorate,
        house: member.australian_house
      })

    r = "mp.php?mpn=#{params2[:mpn]}&mpc=#{params2[:mpc]}&house=#{params2[:house]}"
    r += "&parliament=#{params2[:parliament]}" if params2[:parliament]
    r += "&dmp=#{params2[:dmp]}" if params2[:dmp]
    r += "&display=#{params2[:display]}" if params2[:display]
    r += "##{params2[:anchor]}" if params2[:anchor]
    r
  end

  def members_path(params)
    p = ""
    p += "&parliament=#{params[:parliament]}" if params[:parliament]
    p += "&house=#{params[:house]}" if params[:house] && params[:house] != "representatives"
    p += "&sort=#{params[:sort]}"
    r = "/mps.php"
    r += "?" + p[1..-1] if p != ""
    r
  end

  def members_nav_link(member, members, display, name, title, active, policy = nil)
    params = policy ? {display: display, dmp: policy.id} : {display: display}
    content_tag(:li, class: ("active" if active)) do
      link_to name, member_path2(member, params), title: title
    end
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

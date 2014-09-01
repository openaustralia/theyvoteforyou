module MembersHelper
  def member_path2(member, params = {})
    if member.senator?
      # TODO Seems odd to me the mpc=Senate would expect mpc=Tasmania
      r = "mp.php?mpn=#{member.url_name}&mpc=Senate&house=#{member.australian_house}"
    else
      r = "mp.php?mpn=#{member.url_name}&mpc=#{member.url_electorate}&house=#{member.australian_house}"
    end
    r += "&parliament=#{params[:parliament]}" if params[:parliament]
    r += "&dmp=#{params[:dmp]}" if params[:dmp]
    r += "&display=#{params[:display]}" if params[:display]
    r += "##{params[:anchor]}" if params[:anchor]
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

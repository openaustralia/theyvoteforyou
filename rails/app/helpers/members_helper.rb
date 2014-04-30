module MembersHelper
  def member_path(member, params = {}, member2 = nil)
    if member.senator?
      # TODO Seems odd to me the mpc=Senate would expect mpc=Tasmania
      r = "mp.php?mpn=#{member.url_name}&mpc=Senate&house=#{member.australian_house}"
      r += "&mpn2=#{member2.url_name}&mpc2=Senate&house2=#{member2.australian_house}" if member2
    else
      r = "mp.php?mpn=#{member.url_name}&mpc=#{member.electorate}&house=#{member.australian_house}"
      r += "&mpn2=#{member2.url_name}&mpc2=#{member2.electorate}&house2=#{member2.australian_house}" if member2
    end
    r += "&parliament=#{params[:parliament]}" if params[:parliament]
    r += "&display=#{params[:display]}" if params[:display]
    r += "&dmp=#{params[:dmp]}" if params[:dmp]
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

  def sort_link(sort, sort_name, name, current_sort)
    if current_sort == sort
      content_tag(:b, name)
    else
      link_to name, members_path(params.merge(sort: sort)), alt: "Sort by #{sort_name}"
    end
  end

  def display_link2(member, members, electorate, display, name, title, current_display)
    if current_display == display
      content_tag(:li, name, class: "on")
    else
      content_tag(:li, class: "off") do
        path = if members && members.count > 1
          electorate_path2(electorate, display: display)
        else
          member_path(member, display: display)
        end
        link_to name, path, title: title, class: "off"
      end
    end
  end

  def vote_records_start_date(member)
    # HACK WARNING
    [member.entered_house, Date.new(2006,1,1)].max.strftime("%-d&nbsp;%b&nbsp;%Y").html_safe
  end

  def member_until(member)
    member.left_house > Date.today ? 'still in office' : member.left_house.strftime("%-d&nbsp;%b&nbsp;%Y").html_safe
  end
end

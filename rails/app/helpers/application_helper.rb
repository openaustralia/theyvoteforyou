module ApplicationHelper
  def member_path(member)
    if member.senator?
      # TODO Seems odd to me the mpc=Senate would expect mpc=Tasmania
      "mp.php?mpn=#{member.url_name}&mpc=Senate&house=#{member.australian_house}"
    else
      "mp.php?mpn=#{member.url_name}&mpc=#{member.electorate}&house=#{member.australian_house}"
    end
  end

  def electorate_path(member)
    "mp.php?mpc=#{member.electorate}"
  end

  def sort_link(sort, sort_name, name, current_sort)
    if current_sort == sort
      content_tag(:b, name)
    else
      link_to name, params.merge(sort: sort), alt: "Sort by #{sort_name}"
    end
  end
end

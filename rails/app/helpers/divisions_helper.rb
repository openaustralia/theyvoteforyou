module DivisionsHelper
  # Rather than using url_for which would be the sensible thing, we're constructing the paths
  # by hand to match the order in the php app
  def divisions_path(q)
    p = ""
    p += "&rdisplay=#{q[:rdisplay]}" if q[:rdisplay]
    p += "&rdisplay2=#{q[:rdisplay2]}" if q[:rdisplay2]
    p += "&house=#{q[:house]}" if q[:house]
    p += "&sort=#{q[:sort]}" if q[:sort]
    r = "/divisions.php"
    r += "?" + p[1..-1] if p != ""
    r
  end

  def division_path(q)
    p = ""
    p += "&date=#{q[:date]}" if q[:date]
    p += "&number=#{q[:number]}" if q[:number]
    p += "&display=#{q[:display]}" if q[:display]
    p += "&sort=#{q[:sort]}" if q[:sort]
    r = "division.php"
    r += "?" + p[1..-1] if p != ""
    r
  end

  def sort_link_divisions(sort, sort_name, name, current_sort)
    if current_sort == sort
      content_tag(:b, name)
    else
      link_to name, divisions_path(params.merge(sort: sort)), alt: "Sort by #{sort_name}"
    end
  end
end

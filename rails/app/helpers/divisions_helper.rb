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
end

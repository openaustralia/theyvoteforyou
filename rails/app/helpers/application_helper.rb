module ApplicationHelper
  def electorate_path(member)
    "mp.php?mpc=#{member.electorate}"
  end

  # When there's a link to an electorate it's only for the house of reps
  def electorate_path2(electorate, params = {})
    r = "mp.php?mpc=#{electorate}&house=representatives"
    r += "&display=#{params[:display]}" if params[:display]
    r += "##{params[:anchor]}" if params[:anchor]
    r
  end

  def policy_path(policy, params = {})
    r = "policy.php?id=#{policy.id}"
    r += "&display=#{params[:display]}" if params[:display]
    r
  end

  def sort_link(sort, sort_name, name, current_sort)
    if current_sort == sort
      content_tag(:b, name)
    else
      link_to name, params.merge(sort: sort), alt: "Sort by #{sort_name}"
    end
  end

  # Returns Representatives or Senators
  def members_type(house)
    case house
    when "representatives"
      "Representatives"
    when "senate"
      "Senators"
    when "all"
      "Representatives and Senators"
    else
      raise
    end
  end

  def members_type_long(house)
    case house
    when "representatives"
      "Members of the House of Representatives"
    when "senate"
      "Senators"
    when "all"
      "Members of both Houses of the Federal Parliament"
    else
      raise
    end
  end

  def member_type(house)
    case house
    when "representatives"
      "Representative"
    when "senate"
      "Senator"
    else
      raise
    end
  end

  def electorate_label(house)
    case house
    when "representatives"
      "Electorate"
    when "senate"
      "State"
    when "all"
      "Electorate / State"
    else
      raise
    end
  end
end

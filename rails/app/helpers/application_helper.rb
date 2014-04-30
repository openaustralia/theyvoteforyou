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

  def parliament_name(parliament)
    if Parliament.all[parliament]
      "#{Parliament.all[parliament][:name]}&nbsp;Parliament".html_safe
    elsif parliament.nil?
      "Current"
    elsif parliament == "all"
      "All on record"
    else
      raise
    end
  end

  def current_user
    User.find_by_user_name session[:user_name]
  end

  def user_signed_in?
    !!current_user
  end
end

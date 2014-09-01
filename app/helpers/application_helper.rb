module ApplicationHelper
  def electorate_path(member)
    member_path(mpc: member.url_electorate)
  end

  def electorate_path2(member, params = {})
    member_path(params.merge({
        mpc: (member.url_electorate if member),
        house: (member.australian_house if member)
      }))
  end

  def policy_path(policy, params = {})
    r = "policy.php?id=#{policy.id}"
    r += "&display=#{params[:display]}" if params[:display]
    r
  end

  def edit_division_path(division)
    "account/wiki.php?type=motion&date=#{division.date}&number=#{division.number}&house=#{division.australian_house}&rr=#{CGI.escape(request.fullpath)}"
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

  def fraction_to_percentage_display(fraction, options = {})
    if fraction
      percentage = fraction * 100
      number_to_percentage(percentage, options)
    else
      'n/a'
    end
  end

  def formatted_date(date, include_nbsp = false)
    include_nbsp ? date.strftime("%-d&nbsp;%b&nbsp;%Y").html_safe : date.strftime("%-d %b %Y")
  end
end

module ApplicationHelper
  def nav_link(name, path, title, current)
    content_tag(:li, class: ("active" if current)) do
      link_to name, path, title: title
    end
  end

  def nav_link_unless_current(name, path, title)
    nav_link(name, path, title, current_page?(path))
  end

  def nav_button_link(name, path, title, current)
    link_to name, path, title: title, class: "btn btn-sm btn-default" + (current ? " active" : "")
  end

  def electorate_path2(member)
    electorate_path({
        mpc: (member.url_electorate.downcase if member),
        house: (member.australian_house if member)
      })
  end

  def party_divisions_path2(party)
    party_divisions_path(party: party.downcase.gsub(" ", "_"))
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

  def fraction_to_percentage_display(fraction, options = {precision: 2, significant: true})
    if fraction
      percentage = fraction * 100
      number_to_percentage(percentage, options)
    else
      'n/a'
    end
  end

  def formatted_date(date, include_nbsp = false)
    include_nbsp ? date.strftime(date.strftime("#{date.day.ordinalize}&nbsp;%b&nbsp;%Y, ")).html_safe : date.strftime(date.strftime("#{date.day.ordinalize} %b %Y, "))
  end
end

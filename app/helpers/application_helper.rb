module ApplicationHelper
  def default_meta_description
    "Discover how your MP votes on the issues that matter to you."
  end

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

  def body_class
    if current_page?(controller: "/home", action: "about")
      "about"
    else
      controller.controller_path
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
    when "rada"
      "народний депутат"
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
    when "rada"
      "Верхо́вна Ра́да Украї́ни"
    else
      raise
    end
  end

  def electorate_label(house)
    case house
    when nil
      "Electorate / State"
    when "representatives"
      "Electorate"
    when "senate"
      "State"
    when "rada"
      "Обраний по"
    else
      raise
    end
  end

  def fraction_to_percentage_display(fraction, options = {precision: 2, significant: true})
    if fraction
      percentage = fraction * 100
      number_to_percentage(percentage, options)
    else
      "n/a"
    end
  end

  def formatted_month(month)
    Date.parse("#{month}-01").strftime("%B %Y")
  end

  def formatted_date(date, include_nbsp = false)
    include_nbsp ? date.strftime("#{date.day.ordinalize}&nbsp;%b&nbsp;%Y").html_safe : date.strftime("#{date.day.ordinalize} %b %Y")
  end

  def inline_project_name
    content_tag(:em, Settings.project_name, class: "project-name")
  end
end

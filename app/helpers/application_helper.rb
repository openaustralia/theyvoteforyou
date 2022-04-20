# frozen_string_literal: true

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
    link_to name, path, title: title, class: "btn btn-sm btn-default#{current ? ' active' : ''}"
  end

  def body_class
    if current_page?({ controller: "/home", action: "about" })
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

  def fraction_to_percentage_display(fraction)
    if fraction
      percentage = fraction * 100
      # Special handling for number very close to 0 or 100
      # These are numbers that would get rounded to 0% or 100% but are not exactly that so we want
      # to make it clear that those number are different by using higher precision. We figure out
      # the precision which rounds it to a value that doesn't look like 0 or 100.
      precision = if percentage.positive? && percentage < 0.5
                    -Math.log10(2 * percentage).floor
                  elsif percentage >= 99.5 && percentage < 100
                    -Math.log10(2 * (100 - percentage)).floor
                  else
                    0
                  end
      number_to_percentage(percentage, precision: precision)
    else
      "n/a"
    end
  end

  # A slightly modified version of the helper above as only used in:
  # app/views/feeds/mp_info.xml.builder
  def fraction_to_percentage_display_mp_info(fraction)
    if fraction
      number_to_percentage(fraction * 100, precision: 2)
    else
      "n/a"
    end
  end

  def formatted_month(month)
    Date.parse("#{month}-01").strftime("%B %Y")
  end

  def formatted_date(date)
    date.strftime("#{date.day.ordinalize} %b %Y")
  end

  def inline_project_name
    content_tag(:em, Settings.project_name, class: "project-name")
  end

  # Put the rest of the content in a block
  def optional_strong(strong, &block)
    content = capture(&block)
    strong ? content_tag(:strong, content) : content
  end
end

module MembersHelper
  def sort_link(sort, sort_name, name, current_sort)
    if current_sort == sort
      content_tag(:b, name)
    else
      link_to name, params.merge(sort: sort), alt: "Sort by #{sort_name}"
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
end

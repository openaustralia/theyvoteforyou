module MembersHelper
  def sort_link(sort, sort_name, name, current_sort)
    if current_sort == sort
      content_tag(:b, name)
    else
      link_to name, params.merge(sort: sort), alt: "Sort by #{sort_name}"
    end
  end
end

# frozen_string_literal: true

module UsersHelper
  def name_with_badge(user)
    out = []
    out << link_to_unless_current(user.name, user)
    if user.staff
      out << " "
      out << content_tag(:span, "staff", class: %w[label label-default staff])
    end
    safe_join(out)
  end
end

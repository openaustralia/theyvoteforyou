module PoliciesHelper
  def policy_nav_link(display, name, title, current_display)
    content_tag(:li, class: ("active" if current_display == display)) do
      link_to name, policy_path(Policy.find(params[:id]), display: display), title: title
    end
  end
end

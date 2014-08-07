module PoliciesHelper
  def policy_nav_link(display, name, title, current_display)
    if current_display == display
      content_tag(:li, name, class: "on")
    else
      content_tag(:li, class: "off") do
        link_to name, policy_path(Policy.find(params[:id]), display: display), title: title, class: "off"
      end
    end
  end
end

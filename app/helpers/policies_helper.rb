module PoliciesHelper
  def policy_nav_link(display, name, title, current_display)
    content_tag(:li, class: ("active" if current_display == display)) do
      link_to name, policy_path(Policy.find(params[:id]), display: display), title: title
    end
  end

  def policies_list_sentence(policies)
    policies.map do |policy|
      text = link_to policy.name, policy
      text += " ".html_safe + content_tag(:em, "(provisional)") if policy.provisional?
      text
    end.to_sentence
  end
end

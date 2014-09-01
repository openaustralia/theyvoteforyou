module PoliciesHelper
  def policy_nav_link(display, name, title, current_display)
    nav_link(name, policy_path2(Policy.find(params[:id]), display: display), title, current_display == display)
  end
end

class HomeController < ApplicationController
  def index
    @title = "The Public Whip &#8212; ".html_safe
    @register_url = "/account/register.php?r=%2F".html_safe
    @login_url = "/account/settings.php?r=%2F".html_safe
  end
end

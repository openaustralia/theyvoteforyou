class MembersController < ApplicationController
  def index
    @title = "Representatives &#8212; Current &#8212; The Public Whip".html_safe
    @register_url = "/account/register.php?r=%2Fmps.php".html_safe
    @login_url = "/account/settings.php?r=%2Fmps.php".html_safe
  end
end

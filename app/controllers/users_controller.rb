class UsersController < ApplicationController
  before_action :authenticate_user!

  def show
    user = User.find(params[:id])
    # For the time being only allowed to look at your own profile
    if user != current_user
      render text: "unauthorized", status: :unauthorized
    end
  end
end

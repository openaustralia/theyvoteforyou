class UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
    @you = (current_user && @user == current_user)
  end
end

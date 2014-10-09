class UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
    @you = (current_user && @user == current_user)
    @policies = @you ? @user.policies : @user.policies.visible
  end
end

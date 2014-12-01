class UsersController < ApplicationController
  before_action :authenticate_user!, only: :subscriptions

  def show
    @user = User.find(params[:id])
    @you = (current_user && @user == current_user)

    @history = PaperTrail::Version.where(whodunnit: @user).limit(20) +
    WikiMotion.where(user: @user).limit(20)
    @history = @history.sort_by {|v| -v.created_at.to_i}.take(20)
  end

  def subscriptions
    @user = User.find(params[:id])
  end
end

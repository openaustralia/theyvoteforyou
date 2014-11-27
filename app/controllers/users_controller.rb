class UsersController < ApplicationController
  before_action :authenticate_user!, only: :subscriptions

  def show
    @user = User.find(params[:id])
    @you = (current_user && @user == current_user)
  end

  def subscriptions
    @user = User.find(params[:id])
  end
end

class UsersController < ApplicationController
  before_action :authenticate_user!, only: :subscriptions

  def show
    @user = User.find(params[:id])
    @you = (current_user && @user == current_user)
    @history = @user.recent_changes(20)
  end

  def subscriptions
    @user = User.find(params[:id])
  end

  def confirm
    # Remove Devise flash
    flash.delete(:notice)
  end

  def welcome
    @policies = Policy.order("updated_at DESC").limit(3)
    # TODO: don't include policies that the user is already subscribed to
    # TODO: add a forth policy to @policies from a more random selection
  end
end

class UsersController < ApplicationController
  before_action :authenticate_user!, only: :subscriptions

  def show
    @user = User.find(params[:id])
    @you = (current_user && @user == current_user)

    @history = PaperTrail::Version.where("created_at > ?", 1.week.ago).where(whodunnit: @user) +
    WikiMotion.where("edit_date > ?", 1.week.ago).where(user: @user)
    @history.sort_by! {|v| -v.created_at.to_i}
  end

  def subscriptions
    @user = User.find(params[:id])
  end
end

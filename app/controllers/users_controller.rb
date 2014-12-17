class UsersController < ApplicationController
  before_action :authenticate_user!, only: [:subscriptions, :welcome]

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
    unwatched_policies = Policy.visible.not_watched_by(current_user)
    random_recently_edited_policy = unwatched_policies.order(updated_at: :desc).limit(3).offset(rand(3))[0..0]
    random_policies = unwatched_policies.where.not(id: random_recently_edited_policy).offset(rand(unwatched_policies.count - 1))[0..1]
    #TODO: Replace 1 random_policy with random_most_subscribed_policy
    @policies = random_policies + random_recently_edited_policy
  end
end

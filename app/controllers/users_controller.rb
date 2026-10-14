# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :authenticate_user!, only: %i[subscriptions welcome]

  def show
    @user = User.find(params[:id])
    @you = current_user && @user == current_user
    @history = @user.recent_changes(20)
  end

  def subscriptions
    @user = User.find(params[:id])
    # Only on a person's own page, so nobody learns whether someone else's email bounced
    @email_suppression = @user.email_suppression if @user == current_user
  end

  def confirm
    # Remove Devise flash
    flash.delete(:notice)
  end

  def welcome
    @policies = current_user.unwatched_policies.published.sample(3)
    flash.delete(:notice)
  end
end

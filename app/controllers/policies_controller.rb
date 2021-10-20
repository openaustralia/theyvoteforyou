# frozen_string_literal: true

class PoliciesController < ApplicationController
  before_action :authenticate_user!, except: %i[index drafts show history]

  def index
    @policies = Policy.published.order(:name)
  end

  def drafts
    @policies = Policy.provisional.order(:name)
  end

  def show
    @policy = Policy.find(params[:id])
    return if params[:mpc].nil? || params[:mpn].nil?

    electorate = params[:mpc].gsub("_", " ")
    name = params[:mpn].gsub("_", " ")

    @member = Member.with_name(name)
    @member = @member.in_house(params[:house])
    @member = @member.where(constituency: electorate)
    @member = @member.order(entered_house: :desc).first

    if @member
      # Pick the member where the votes took place
      @member = @member.person.member_for_policy(@policy)
      render "show_with_member"
    else
      render "members/member_not_found", status: :not_found
    end
  end

  def edit
    @policy = Policy.find(params[:id])
  end

  def new
    @policy = Policy.new
  end

  def create
    @policy = Policy.new policy_params
    @policy.user = current_user
    @policy.private = 2
    if @policy.save
      redirect_to @policy, notice: "Successfully made new policy"
    else
      render "new"
    end
  end

  def update
    @policy = Policy.find(params[:id])

    if @policy.update policy_params
      @policy.alert_watches(@policy.versions.last)
      redirect_to @policy, notice: "Policy updated."
    else
      render :edit
    end
  end

  def history
    @policy = Policy.find(params[:id])
    @history = PaperTrail::Version.where(policy_id: @policy.id).order(created_at: :desc)
  end

  def watch
    @policy = Policy.find(params[:id])
    current_user.toggle_policy_watch(@policy)
    flash[:notice] = "Unsubscribed" unless current_user.watching?(@policy)
    redirect_to :back
  end

  private

  def policy_params
    params.require(:policy).permit(:name, :description).merge(private: (params[:provisional] ? 2 : 0))
  end
end

# frozen_string_literal: true

class PoliciesController < ApplicationController
  before_action :authenticate_user!, except: %i[index drafts show history]

  def index
    @policies = Policy.published
    @sort = params[:sort]

    case @sort
    when "name"
      @policies = @policies.order(:name)
    when "date"
      @policies = @policies.order("updated_at DESC")
    else
      @policies = @policies.left_joins(:watches).group(:id).order(Arel.sql("COUNT(watches.id) DESC"))
      @sort = nil
    end
  end

  def drafts
    @policies = Policy.provisional.order(:name)
  end

  def show
    @policy = Policy.find(params[:id])
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
    redirect_back(fallback_location: @policy)
  end

  private

  def policy_params
    params.require(:policy).permit(:name, :description).merge(private: (params[:provisional] ? 2 : 0))
  end
end

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
    @sort = params[:sort]
    @categories = PolicyPersonDistance.all_categories(reverse: (@sort == "against"))
    @cardtype = params[:type]
    return if params[:card].nil?

    if params[:category]
      @category = params[:category]
      @card_title, @rep, @number_left = helpers.policy_member_category(@policy, params[:category], max_person: 19)
      render "card/policy_category_card", layout: "card_layout"
    else
      @people, @number_left = helpers.shortened_randomised_people_voting_on_policy(@policy, max_people: 19)
      render "card/policy_card", layout: "card_layout"
    end
  end

  def new
    @policy = Policy.new
    authorize @policy
  end

  def edit
    @policy = Policy.find(params[:id])
    authorize @policy
  end

  def create
    @policy = Policy.new policy_params
    @policy.user = current_user
    @policy.private = 2
    authorize @policy
    if @policy.save
      redirect_to @policy, notice: "Successfully made new policy"
    else
      render "new"
    end
  end

  def update
    @policy = Policy.find(params[:id])
    authorize @policy

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
    params.expect(policy: %i[name description]).merge(private: (params[:provisional] ? 2 : 0))
  end
end

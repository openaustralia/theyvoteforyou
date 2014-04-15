class PoliciesController < ApplicationController
  def index
    @policies = Policy.joins(:policy_info).order(dream_id: :desc)
  end

  def show
    @policy = Policy.find(params[:id])
  end
end

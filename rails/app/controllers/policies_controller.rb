class PoliciesController < ApplicationController
  def index
    @policies = Policy.joins(:policy_info).order(:private, :name)
  end

  def show
    @policy = Policy.find(params[:id])
    @display = params[:display]
  end
end

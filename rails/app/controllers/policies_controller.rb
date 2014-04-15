class PoliciesController < ApplicationController
  def index
    @policies = Policy.joins(:policy_info)
  end

  def show
    @policy = Policy.find(params[:id])
  end
end

class PoliciesController < ApplicationController
  def index
    @policies = Policy.all
  end

  def show
    @policy = Policy.find(params[:id])
  end
end

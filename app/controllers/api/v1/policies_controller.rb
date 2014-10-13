class Api::V1::PoliciesController < ApplicationController
  def index
    @policies = Policy.order(:id).all
  end

  def show
    @policy = Policy.find(params[:id])
  end
end

# frozen_string_literal: true

class Api::V1::PoliciesController < Api::V1::ApplicationController
  def index
    @policies = Policy.order(:id).all
  end

  def show
    @policy = Policy.find(params[:id])
  end
end

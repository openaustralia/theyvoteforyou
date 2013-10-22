class PoliciesController < ApplicationController
  def index
    @policies = Policy.all
  end

  def show
  end
end

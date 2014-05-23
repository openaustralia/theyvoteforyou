class EditsController < ApplicationController
  def show
    @division = Division.in_australian_house(params[:house] || "representatives").find_by!(date: params[:date], number: params[:number])
  end
end

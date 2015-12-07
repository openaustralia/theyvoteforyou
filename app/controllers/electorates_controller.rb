class ElectoratesController < ApplicationController
  def show_redirect
    redirect_to params.merge(only_path: true, display: nil, dmp: nil, house: (params[:house] || "representatives")).to_h
  end

  def show
    electorate = electorate_param
    house = params[:house]

    @members = Member.where(constituency: electorate).order(entered_house: :desc)
    @members = @members.in_house(house) if house
    @member = @members.first
    raise ActiveRecord::RecordNotFound if @member.nil?
  end
end

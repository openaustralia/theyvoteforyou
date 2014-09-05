class ElectoratesController < ApplicationController
  def show
    electorate = params[:mpc].gsub("_", " ") if params[:mpc]
    house = params[:house]

    if params[:display] || params[:dmp]
      redirect_to params.merge(display: nil, dmp: nil)
      return
    end
    @members = Member.where(constituency: electorate).order(entered_house: :desc)
    @members = @members.in_australian_house(house) if house
    @member = @members.first
    if @member
      render "members/show_electorate"
    else
      render "members/member_not_found", status: 404
    end
  end
end

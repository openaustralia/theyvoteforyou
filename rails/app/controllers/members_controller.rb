class MembersController < ApplicationController
  def index
    @sort = params[:sort]
    # By default sort by last name
    @sort = "lastname" if @sort.nil?

    if @sort == "rebellions"
      @short_title = "Rebel Representatives &#8212; Current".html_safe
    else
      @short_title = "Representatives &#8212; Current".html_safe
    end
    @title = @short_title + " &#8212; The Public Whip".html_safe

    order = case @sort
    when "lastname"
      ["last_name", "first_name"]
    when "constituency"
      ["constituency"]
    when "party"      
      ["party", "last_name", "first_name"]
    when "rebellions"
      ["rebellions_fraction DESC", "last_name", "first_name"]
    when "attendance"
      ["attendance_fraction DESC", "last_name", "first_name"]
    else
      raise "Unexpected value"
    end

    @members = Member.current.where(house: "commons").joins(:member_info).select("*, votes_attended/votes_possible as attendance_fraction, rebellions/votes_attended as rebellions_fraction").order(order)
  end
end

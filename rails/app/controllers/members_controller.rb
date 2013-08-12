# encoding: UTF-8

class MembersController < ApplicationController
  def index
    @sort = params[:sort]
    # By default sort by last name
    @sort = "lastname" if @sort.nil?

    @australian_house = params[:house]
    @australian_house = "representatives" if @australian_house.nil?

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

    @members = Member.current.in_australian_house(@australian_house).joins(:member_info).select("*, votes_attended/votes_possible as attendance_fraction, rebellions/votes_attended as rebellions_fraction").order(order)
  end

  def show
    @first_name = params[:mpn].split("_")[0]
    @last_name = params[:mpn].split("_")[1]
    @electorate = params[:mpc]
    @australian_house = params[:house]
    @display = params[:display]

    # TODO In reality there could be several members matching this and we should relate this back to being
    # a single person
    if @electorate == "Senate"
      @member = Member.in_australian_house(@australian_house).where(first_name: @first_name, last_name: @last_name).first
    else
      @member = Member.in_australian_house(@australian_house).where(first_name: @first_name, last_name: @last_name, constituency: @electorate).first
    end

    if @display == "allvotes"
      # divisions attended
      @divisions = @member.divisions.order(division_date: :desc, clock_time: :desc, division_name: :asc)
    elsif @display == "everyvote"
      # All divisions MP could have attended
      @divisions = @member.divisions_possible.order(division_date: :desc, clock_time: :desc, division_name: :asc)
    elsif @display.nil?
      # Interesting divisions
      @divisions = @member.interesting_divisions.order(division_date: :desc, clock_time: :desc, division_name: :asc)
    end
  end
end

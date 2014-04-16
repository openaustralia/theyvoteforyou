class MembersController < ApplicationController
  def index
    @sort = params[:sort]
    # By default sort by last name
    @sort = "lastname" if @sort.nil?

    @house = params[:house]
    @house = "representatives" if @house.nil?

    @parliament = params[:parliament]

    order = case @sort
    when "lastname"
      ["last_name", "first_name"]
    when "constituency"
      ["constituency", "last_name"]
    when "party"      
      ["party", "last_name", "first_name"]
    when "rebellions"
      ["rebellions_fraction DESC", "last_name", "first_name"]
    when "attendance"
      ["attendance_fraction DESC", "last_name", "first_name"]
    else
      raise "Unexpected value"
    end

    # FIXME: Should be easy to refactor this, just doing the dumb thing right now
    # BUG: Doing a join on member_info returns less MPs in my test data than there are in the DB
    if @parliament.nil?
      @members = Member.current.in_australian_house(@house).joins(:member_info).select("*, votes_attended/votes_possible as attendance_fraction, rebellions/votes_attended as rebellions_fraction").order(order)
    elsif @parliament == "all"
      @members = Member.in_australian_house(@house).joins(:member_info).select("*, votes_attended/votes_possible as attendance_fraction, rebellions/votes_attended as rebellions_fraction").order(order)
    elsif Parliament.all[@parliament]
      @members = Member.where("? >= entered_house AND ? < left_house", Parliament.all[@parliament][:to], Parliament.all[@parliament][:from]).in_australian_house(@house).joins(:member_info).select("*, votes_attended/votes_possible as attendance_fraction, rebellions/votes_attended as rebellions_fraction").order(order)
    else
      raise
    end
  end

  def show
    if params[:mpn]
      name = params[:mpn].split("_")
      # Strip titles like "Ms"
      name.slice!(0) if name[0] == 'Ms' || name[0] == 'Mrs'
      @first_name = name[0]
      @last_name = name[1..-1].join(' ')
    end
    electorate = params[:mpc]
    @house = params[:house] || "representatives"
    @display = params[:display]

    # TODO In reality there could be several members matching this and we should relate this back to being
    # a single person
    if electorate == "Senate" || electorate.nil?
      @member = Member.in_australian_house(@house).where(first_name: @first_name, last_name: @last_name).first
    elsif @first_name && @last_name
      @member = Member.in_australian_house(@house).where(first_name: @first_name, last_name: @last_name, constituency: electorate).first
    else
      # TODO This is definitely wrong. Should return multiple members in this electorate
      # TEMP HACK hardcoded date 1 Jan 2006 (start of Hansard data)
      @members = Member.in_australian_house(@house).where(constituency: electorate).order(entered_house: :desc)
      @member = Member.in_australian_house(@house).where(constituency: electorate).order(entered_house: :desc).where("left_house >= ?", Date.new(2006,1,1)).first
      if @members.count > 1
        @electorate = electorate
      end
    end

    # Does this belong here?
    raise ActiveRecord::RecordNotFound if !@member

    if @display == "allvotes"
      # divisions attended
      @divisions = @member.divisions.order(division_date: :desc, clock_time: :desc, division_name: :asc)
    elsif @display == "everyvote"
      # All divisions MP could have attended
      @divisions = @member.divisions_possible.order(division_date: :desc, clock_time: :desc, division_name: :asc)
    elsif @display == "summary" || @display.nil?
      # Interesting divisions
      @divisions = @member.interesting_divisions.order(division_date: :desc, clock_time: :desc, division_name: :asc)
    end
  end
end

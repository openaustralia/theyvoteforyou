class MembersController < ApplicationController
  def index
    @sort = params[:sort]
    @house = params[:house]

    # Redirect if necessary
    if @house == "all" || @house.nil? || @sort == "lastname" || params[:parliament]
      @house = "representatives" if @house == "all" || @house.nil?
      @sort = nil if @sort == "lastname"
      redirect_to members_path(house: @house, sort: @sort)
      return
    end

    order = case @sort
    when nil
      ["last_name", "first_name", "constituency", "party", "entered_house DESC"]
    when "constituency"
      ["constituency", "last_name", "first_name", "party", "entered_house DESC"]
    when "party"
      ["party", "last_name", "first_name", "constituency", "entered_house DESC"]
    when "rebellions"
      ["rebellions_fraction DESC", "last_name", "first_name", "constituency", "party", "entered_house DESC"]
    when "attendance"
      ["attendance_fraction DESC", "last_name", "first_name", "constituency", "party", "entered_house DESC"]
    when "date"
      ["left_house", "last_name", "first_name", "constituency", "party", "entered_house DESC"]
    else
      raise "Unexpected value"
    end

    @members = Member.joins('LEFT OUTER JOIN `member_infos` ON `member_infos`.`member_id` = `members`.`id`').select("members.*, round(votes_attended/votes_possible,10) as attendance_fraction, round(rebellions/votes_attended,10) as rebellions_fraction").in_australian_house(@house).current.order(order).includes(:member_info)
  end

  def show_redirect
    if params[:mpid]
      member = Member.find_by!(id: params[:mpid])
    elsif params[:id]
      member = Member.find_by!(gid: params[:id])
    end
    redirect_to view_context.member_path2(member, dmp: params[:dmp], display: params[:display])
  end

  def show
    electorate = params[:mpc].gsub("_", " ") if params[:mpc]
    name = params[:mpn].gsub("_", " ") if params[:mpn]
    @display = params[:display]

    if params[:showall] == "yes"
      redirect_to params.merge(showall: nil, display: "allvotes")
      return
    end
    if params[:dmp] && params[:display] == "allvotes"
      redirect_to params.merge(display: nil)
      return
    end
    if params[:display] == "summary"
      redirect_to params.merge(display: nil)
      return
    end

    @member = Member.with_name(name)
    @member = @member.in_australian_house(params[:house]) if params[:house]
    @member = @member.where(constituency: electorate) if electorate && electorate != "Senate"
    @member = @member.order(entered_house: :desc).first

    if @member.nil?
      render 'member_not_found', status: 404
      return
    end

    if params[:dmp]
      @policy = Policy.find(params[:dmp])
      # Pick the member where the votes took place
      @member = @member.person.member_for_policy(@policy)
      render "show_policy"
      return
    end

    @members = Member.where(person_id: @member.person_id).order(entered_house: :desc)
    # Trying this hack. Seems mighty weird
    # TODO Get rid of this
    @member = @members.first if @member.senator?
    render "show"
  end
end

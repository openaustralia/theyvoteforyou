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

    @members = Member.joins('LEFT OUTER JOIN `member_infos` ON `member_infos`.`member_id` = `members`.`id`').select("members.*, round(votes_attended/votes_possible,10) as attendance_fraction, round(rebellions/votes_attended,10) as rebellions_fraction").in_australian_house(@house).current.order(order)
  end

  def show
    electorate = params[:mpc].gsub("_", " ") if params[:mpc]
    name = params[:mpn].gsub("_", " ") if params[:mpn]
    @display = params[:showall] == "yes" ? "allvotes" : params[:display]

    if params[:dmp] && params[:display] == "allvotes"
      redirect_to params.merge(display: nil)
      return
    end

    if params[:mpid]
      @member = Member.find_by!(id: params[:mpid])
      redirect_to view_context.member_path2(@member, dmp: params[:dmp])
      return
    elsif params[:id]
      @member = Member.find_by!(gid: params[:id])
    elsif name
      @member = Member.with_name(name)
      @member = @member.in_australian_house(params[:house]) if params[:house]
      @member = @member.where(constituency: electorate) if electorate && electorate != "Senate"
      @member = @member.order(entered_house: :desc).first
    end

    if @member
      @members = Member.where(person_id: @member.person_id).order(entered_house: :desc)

      # Trying this hack. Seems mighty weird
      # TODO Get rid of this
      @member = @members.first if @member.senator?
    else
      @members = Member.where(constituency: electorate).order(entered_house: :desc)
      @members = @members.in_australian_house(params[:house]) if params[:house]
      @member = @members.first
      # TODO If this relates to a single person redirect
      if @display || params[:dmp]
        redirect_to view_context.electorate_path(@member)
        return
      end
    end

    if @member.nil?
      # TODO: This should 404 but doesn't to match the PHP app
      render 'member_not_found'
      return
    end

    if params[:dmp]
      @policy = Policy.find(params[:dmp])
      # Pick the member where the votes took place
      @member = @member.person.member_for_policy(@policy)
      # Not using PolicyPersonDistance.find_by because of the messed up association with the Member model
      unless @policy_member_distance = @member.person.policy_person_distances.find_by(policy: @policy)
        @policy_member_distance = PolicyPersonDistance.new
      end
      @agreement_fraction_with_policy = @member.person.agreement_fraction_with_policy(@policy)
      @number_of_votes_on_policy = @member.person.number_of_votes_on_policy(@policy)
    end

    if @policy
      render "show_policy"
    elsif @members.map{|m| m.person_id}.uniq.count > 1
      render "show_electorate"
    else
      render "show"
    end
  end
end

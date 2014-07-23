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
    member_info_join = 'LEFT OUTER JOIN `pw_cache_mpinfo` ON `pw_cache_mpinfo`.`mp_id` = `pw_mp`.`mp_id`'
    if @parliament.nil?
      @members = Member.current.in_australian_house(@house).joins(member_info_join).select("*, votes_attended/votes_possible as attendance_fraction, rebellions/votes_attended as rebellions_fraction").order(order)
    elsif @parliament == "all"
      @members = Member.in_australian_house(@house).joins(member_info_join).select("*, votes_attended/votes_possible as attendance_fraction, rebellions/votes_attended as rebellions_fraction").order(order)
    elsif Parliament.all[@parliament]
      @members = Member.where("? >= entered_house AND ? < left_house", Parliament.all[@parliament][:to], Parliament.all[@parliament][:from]).in_australian_house(@house).joins(member_info_join).select("*, votes_attended/votes_possible as attendance_fraction, rebellions/votes_attended as rebellions_fraction").order(order)
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
    electorate = electorate.gsub("_", " ") if electorate
    @house = params[:house] || "representatives"
    @display = params[:display]
    @showall = params[:showall] == "yes"

    # TODO In reality there could be several members matching this and we should relate this back to being
    # a single person
    if params[:mpid]
      @member = Member.find_by!(mp_id: params[:mpid])
      # TODO order @members
      @members = Member.where(person: @member.person)
      # We're displaying the members for a single person
      @person = true
    elsif params[:id]
      @member = Member.find_by!(gid: params[:id])
      @members = [@member]
    elsif electorate == "Senate" || electorate.nil?
      @member = Member.in_australian_house(@house).where(first_name: @first_name, last_name: @last_name).first
      @members = [@member]
    elsif @first_name && @last_name
      @member = Member.in_australian_house(@house).where(first_name: @first_name, last_name: @last_name, constituency: electorate).order(entered_house: :desc).first
      @members = [@member]
    else
      # TODO This is definitely wrong. Should return multiple members in this electorate
      # TEMP HACK hardcoded date 1 Jan 2006 (start of Hansard data)
      @members = Member.in_australian_house(@house).where(constituency: electorate).order(entered_house: :desc)
      @member = @members.where("left_house >= ?", Date.new(2006,1,1)).first
      if @members.count > 1
        @electorate = electorate
      end
    end

    if !@member
      # TODO: This should 404 but doesn't to match the PHP app
      render 'member_not_found'
    else
      if params[:dmp]
        @policy = Policy.find(params[:dmp])
        # Not using PolicyMemberDistance.find_by because of the messed up association with the Member model
        unless @policy_member_distance = @member.policy_member_distances.find_by(policy: @policy)
          @policy_member_distance = PolicyMemberDistance.new
        end
        @agreement_fraction_with_policy = @member.agreement_fraction_with_policy(@policy)
        @number_of_votes_on_policy = @member.number_of_votes_on_policy(@policy)
      end
    end
  end
end

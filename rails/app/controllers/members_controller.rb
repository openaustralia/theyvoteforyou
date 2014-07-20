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
      name = Member.first_last_name params[:mpn]
      @first_name = name[:first_name]
      @last_name = name[:last_name]
    end
    if params[:mpn2]
      name = Member.first_last_name params[:mpn2]
      @first_name2 = name[:first_name]
      @last_name2 = name[:last_name]
    end
    electorate = params[:mpc]
    electorate2 = params[:mpc2]
    @house = params[:house] || "representatives"
    @house2 = params[:house2] || "representatives"
    @display = params[:display]

    # TODO In reality there could be several members matching this and we should relate this back to being
    # a single person
    @member = Member.find_by_params params[:mpid], params[:id], electorate, @house, @first_name, @last_name
    @member2 = Member.find_by_params params[:mpid2], params[:id2], electorate2, @house2, @first_name2, @last_name2

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

      if @member2
        #temp hack
        @divisions = @member.conflicting_divisions(@member2)
      elsif @display == "allvotes"
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
end

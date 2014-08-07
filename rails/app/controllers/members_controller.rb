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

    # FIXME: Should be easy to refactor this, just doing the dumb thing right now
    member_info_join = 'LEFT OUTER JOIN `pw_cache_mpinfo` ON `pw_cache_mpinfo`.`mp_id` = `pw_mp`.`mp_id`'
    if @parliament.nil?
      @members = Member.current.in_australian_house(@house).joins(member_info_join).select("*, round(votes_attended/votes_possible,10) as attendance_fraction, round(rebellions/votes_attended,10) as rebellions_fraction").order(order)
    elsif @parliament == "all"
      @members = Member.in_australian_house(@house).joins(member_info_join).select("*, round(votes_attended/votes_possible,10) as attendance_fraction, round(rebellions/votes_attended,10) as rebellions_fraction").order(order)
    elsif Parliament.all[@parliament]
      @members = Member.where("? >= entered_house AND ? < left_house", Parliament.all[@parliament][:to], Parliament.all[@parliament][:from]).in_australian_house(@house).joins(member_info_join).select("*, round(votes_attended/votes_possible,10) as attendance_fraction, round(rebellions/votes_attended,10) as rebellions_fraction").order(order)
    else
      raise
    end

    if params[:bs]
      render "members/bootstrap/index", layout: "bootstrap"
    else
      render "index"
    end
  end

  def show
    if params[:mpn]
      name = MembersController.first_last_name params[:mpn]
      @first_name = name[:first_name]
      @last_name = name[:last_name]
    end
    if params[:mpn2]
      name = MembersController.first_last_name params[:mpn2]
      @first_name2 = name[:first_name]
      @last_name2 = name[:last_name]
    end
    electorate = params[:mpc]
    electorate2 = params[:mpc2]
    electorate = electorate.gsub("_", " ") if electorate
    electorate2 = electorate2.gsub("_", " ") if electorate2
    @house = params[:house]
    @house2 = params[:house2]
    @display = params[:showall] == "yes" ? "allvotes" : params[:display]

    # TODO In reality there could be several members matching this and we should relate this back to being
    # a single person

    @member = MembersController.find_by_params params[:mpid], params[:id], electorate, @house, @first_name, @last_name
    @member2 = MembersController.find_by_params params[:mpid2], params[:id2], electorate2, @house2, @first_name2, @last_name2

    if @member
      @members = Member.where(person: @member.person).order(entered_house: :desc)
      @person = true
    else
      # TODO This is definitely wrong. Should return multiple members in this electorate
      if @house
        @members = Member.in_australian_house(@house).where(constituency: electorate).order(entered_house: :desc)
      else
        @members = Member.where(constituency: electorate).order(entered_house: :desc)
      end
      @member = @members.first
      if @members.count > 1 && @members.map{|m| m.person}.uniq.count > 1
        @electorate = electorate
      end
    end

    # Trying this hack. Seems mighty weird
    if @member.senator?
      @member = @members.first
    end

    if !@member
      # TODO: This should 404 but doesn't to match the PHP app
      render 'member_not_found'
    else
      if params[:dmp]
        @policy = Policy.find(params[:dmp])
        # Pick the member where the votes took place
        @member = @member.member_for_policy(@policy)
        # Not using PolicyMemberDistance.find_by because of the messed up association with the Member model
        unless @policy_member_distance = @member.policy_member_distances.find_by(policy: @policy)
          @policy_member_distance = PolicyMemberDistance.new
        end
        @agreement_fraction_with_policy = @member.agreement_fraction_with_policy(@policy)
        @number_of_votes_on_policy = @member.number_of_votes_on_policy(@policy)
      end

      if @member2
        if @display.nil? || @display == "difference"
          @divisions = @member.conflicting_divisions(@member2).order(division_date: :desc, clock_time: :desc, division_name: :asc)
        elsif @display == "allvotes"
          @divisions = @member.divisions_with(@member2).order(division_date: :desc, clock_time: :desc, division_name: :asc)
        elsif @display == "everyvote"
          # Very fishy how "votes attended" and "all votes" are apparently the
          # same.
          @divisions = @member.divisions_with(@member2).order(division_date: :desc, clock_time: :desc, division_name: :asc)
        end
      end
    end

    if @policy
      render "show_policy"
    elsif @member2
      render "show_member2"
    else
      if params[:bs]
        render "members/bootstrap/show", layout: "bootstrap"
      else
        render "show"
      end
    end
  end

  private

  def self.find_by_params(mpid, id, electorate, house, first_name, last_name)
    if mpid
      Member.find_by!(mp_id: mpid)
    elsif id
      Member.find_by!(gid: id)
    elsif electorate == "Senate" || electorate.nil?
      if house
        Member.in_australian_house(house).where(first_name: first_name, last_name: last_name).order(entered_house: :desc).first
      else
        Member.where(first_name: first_name, last_name: last_name).order(entered_house: :desc).first
      end
    elsif first_name && last_name
      Member.in_australian_house(house).where(first_name: first_name, last_name: last_name, constituency: electorate).order(entered_house: :desc).first
    end
  end

  def self.first_last_name(snake_case_name)
    name = snake_case_name.split("_")
    # Strip titles like "Ms"
    name.slice!(0) if name[0] == 'Ms' || name[0] == 'Mrs' || name[0] == "Mr"
    first_name = name[0]
    last_name = name[1..-1].join(' ')
    {:first_name=>first_name, :last_name=>last_name}
  end
end

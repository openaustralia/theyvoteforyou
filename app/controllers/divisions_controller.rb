class DivisionsController < ApplicationController
  before_action :authenticate_user!, only: [:edit, :update, :create_policy_division, :update_policy_division, :destroy_policy_division]

  def index_redirect
    if params[:rdisplay2] == "rebels"
      redirect_to params.merge(rdisplay2: nil, sort: "rebellions")
    end
  end

  def index
    if params[:mpc] && params[:mpn]
      electorate = params[:mpc].gsub("_", " ")
      name = params[:mpn].gsub("_", " ")

      @member = Member.with_name(name)
      @member = @member.in_australian_house(params[:house])
      @member = @member.where(constituency: electorate)
      @member = @member.order(entered_house: :desc).first

      if @member.nil?
        render 'members/member_not_found', status: 404
      else
        render 'index_with_member'
      end
    else
      @sort = params[:sort]
      @rdisplay = params[:rdisplay]
      @rdisplay = "2013" if @rdisplay.nil?
      @house = params[:house]

      @parties = Division
      @parties = @parties.in_parliament(Parliament.all[@rdisplay]) if @rdisplay != "all"
      @parties = @parties.in_australian_house(@house) if @house
      @parties = @parties.joins(:whips).order("whips.party").select(:party).distinct.map{|d| d.party}

      # We can either use party or rdisplay2 to set the party
      if params[:party]
        @party = params[:party].gsub("_", " ")
      elsif params[:rdisplay2]
        @party = params[:rdisplay2].gsub('_party', '')
      end
      # Match to canonical capitalisation
      @party = @parties.find{|p| p.downcase == @party}

      raise ActiveRecord::RecordNotFound unless @rdisplay == "all" || Parliament.all.has_key?(@rdisplay)

      order = case @sort
      when nil
        ["date DESC", "clock_time DESC", "name", "number DESC"]
      when "subject"
        ["name", "date DESC", "clock_time DESC", "number DESC"]
      when "rebellions"
        ["rebellions DESC", "date DESC", "clock_time DESC", "name", "number DESC"]
      when "turnout"
        ["turnout DESC", "date DESC", "clock_time DESC", "name", "number DESC"]
      else
        raise "Unexpected value"
      end

      @divisions = Division.order(order)
      @divisions = @divisions.joins(:division_info) if @sort == "rebellions" || @sort == "turnout"
      @divisions = @divisions.in_australian_house(@house) if @house
      @divisions = @divisions.in_parliament(Parliament.all[@rdisplay]) if @rdisplay != "all"
      @divisions = @divisions.joins(:whips).where(whips: {party: @party}) if @party
      @divisions = @divisions.includes(:division_info, :wiki_motion)
    end
  end

  def show_redirect
    if params[:sort]
      redirect_to params.merge(sort: nil)
      return
    end
    if params[:display] == "allvotes" || params[:display] == "allpossible"
      redirect_to params.merge(display: nil)
      return
    end
    if params[:house].nil?
      redirect_to params.merge(house: "representatives")
      return
    end
    if params[:mpc] == "Senate"
      house = params[:house]
      first_name = params[:mpn].split("_")[0]
      last_name = params[:mpn].split("_")[1]

      member = Member.in_australian_house(house).where(first_name: first_name, last_name: last_name).first
      redirect_to params.merge(mpc: member.url_electorate)
    end
  end

  def show
    house = params[:house]
    @division = Division.in_australian_house(house).find_by!(date: params[:date], number: params[:number])

    # If a member is included
    if params[:mpn] && params[:mpc]
      name = params[:mpn].gsub("_", " ")
      electorate = params[:mpc].gsub("_", " ")
      # TODO Also ensure that the member is current on the date of this division
      member = Member.in_australian_house(house).with_name(name).
        where(constituency: electorate).first
      @member = member.person.member_who_voted_on_division(@division)
    end
    @members = Member.in_australian_house(house).current_on(@division.date).
      joins("LEFT OUTER JOIN votes ON members.id = votes.member_id AND votes.division_id = #{@division.id}").
      order("members.party", "vote", "members.last_name", "members.first_name")
  end

  def show_policies
    @display = "policies"
    @division = Division.in_australian_house(params[:house]).find_by!(date: params[:date], number: params[:number])
    @policy_division = @division.policy_divisions.new
  end

  def edit
    @division = Division.in_australian_house(params[:house] || 'representatives').find_by!(date: params[:date], number: params[:number])
  end

  def history
    @division = Division.in_australian_house(params[:house] || "representatives").find_by!(date: params[:date], number: params[:number])
  end

  def update
    @division = Division.in_australian_house(params[:house] || 'representatives').find_by!(date: params[:date], number: params[:number])

    wiki_motion = @division.build_wiki_motion(params[:newtitle], params[:newdescription], current_user)

    if wiki_motion.save
      redirect_to view_context.division_path(@division), notice: 'Division updated'
    else
      redirect_to view_context.edit_division_path(@division), alert: 'Could not update division'
    end
  end

  def create_policy_division
    @division = Division.in_australian_house(params[:house]).find_by!(date: params[:date], number: params[:number])
    @policy_division = @division.policy_divisions.new(policy_division_params)

    if @policy_division.save
      # TODO Just point to the object when the path helper has been refactored
      redirect_to division_policies_path(house: @division.australian_house, date: @division.date, number: @division.number)
    else
      flash[:error] = 'Could not connect policy'
      @display = "policies"
      render 'show_policies'
    end
  end

  def update_policy_division
    division = Division.in_australian_house(params[:house]).find_by!(date: params[:date], number: params[:number])
    policy_division = PolicyDivision.find_by!(division: division, policy: params[:policy_id])

    if policy_division.update(policy_division_params)
      flash[:notice] = 'Updated policy connection'
    else
      flash[:error] = 'Could not update policy connection'
    end

    # TODO Just point to the object when the path helper has been refactored
    redirect_to division_policies_path(house: division.australian_house, date: division.date, number: division.number)
  end

  def destroy_policy_division
    division = Division.in_australian_house(params[:house]).find_by!(date: params[:date], number: params[:number])
    policy_division = PolicyDivision.find_by!(division: division, policy: params[:policy_id])

    if policy_division.destroy
      flash[:notice] = 'Removed policy connection'
    else
      flash[:error] = 'Could not remove policy connection'
    end

    # TODO Just point to the object when the path helper has been refactored
    redirect_to division_policies_path(house: division.australian_house, date: division.date, number: division.number)
  end

  private

  def policy_division_params
    params.require(:policy_division).permit(:policy_id, :vote)
  end
end

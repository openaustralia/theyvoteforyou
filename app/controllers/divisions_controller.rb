class DivisionsController < ApplicationController
  # TODO: Reenable CSRF protection
  skip_before_action :verify_authenticity_token

  before_action :authenticate_user!, only: [:edit, :update, :add_policy_vote]

  def index_redirect
    if params[:rdisplay2] == "rebels"
      redirect_to params.merge(rdisplay2: nil, sort: "rebellions")
    end
  end

  def index
    @sort = params[:sort]
    @rdisplay = params[:rdisplay]
    @rdisplay = "2013" if @rdisplay.nil?
    @rdisplay2 = params[:rdisplay2]
    @house = params[:house]

    if @house
      if @rdisplay != "all"
        @parties = Division.in_parliament(Parliament.all[@rdisplay])
      else
        @parties = Division
      end
      @parties = @parties.in_australian_house(@house).joins(:whips).order("whips.party").select(:party).distinct.map{|d| d.party}
    end

    if @rdisplay2
      if @parties.include? @rdisplay2.gsub('_party', '')
        @party = @rdisplay2.gsub('_party', '')
      else
        @rdisplay2 = nil
      end
    end

    raise "Invalid rdisplay param" unless @rdisplay == "all" || Parliament.all.has_key?(@rdisplay)

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
    @divisions = @divisions.includes(:whips, :division_info, :wiki_motions)
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
  end

  def show_policies
    @display = "policies"
    @division = Division.in_australian_house(params[:house]).find_by!(date: params[:date], number: params[:number])
    if params[:dmp]
      @policy = Policy.find(params[:dmp])
    elsif user_signed_in?
      @policy = current_user.active_policy
    end
  end

  def show
    house = params[:house]
    @division = Division.in_australian_house(house).find_by!(date: params[:date], number: params[:number])

    # If a member is included
    if params[:mpn] && params[:mpc]
      first_name = params[:mpn].split("_")[0]
      last_name = params[:mpn].split("_")[1]
      electorate = params[:mpc].gsub("_", " ")
      # TODO Also ensure that the member is current on the date of this division
      member = Member.in_australian_house(house).where(first_name: first_name, last_name: last_name)
      member = member.where(constituency: electorate) if electorate != "Senate"
      member = member.first
      @member = member.person.member_who_voted_on_division(@division)
    end
    @members = Member.in_australian_house(house).current_on(@division.date).joins("LEFT OUTER JOIN votes ON members.id = votes.member_id AND votes.division_id = #{@division.id}").order("members.party", "vote", "members.last_name", "members.first_name")
  end

  def edit
    @division = Division.in_australian_house(params[:house] || 'representatives').find_by!(date: params[:date], number: params[:number])
  end

  # TODO Rename to history
  def show_edits
    @division = Division.in_australian_house(params[:house] || "representatives").find_by!(date: params[:date], number: params[:number])
  end

  def update
    @division = Division.in_australian_house(params[:house] || 'representatives').find_by!(date: params[:date], number: params[:number])

    # TODO: Provide some feedback to the user about how their save went
    # This is just matching the PHP app right now :(
    if params[:submit] == 'Save'
      @division.create_wiki_motion! params[:newtitle], params[:newdescription], current_user
    end

    params[:rr] ? redirect_to(params[:rr]) : render(:edit)
  end

  def add_policy_vote
    @display = params[:display]
    @division = Division.in_australian_house(params[:house] || "representatives").find_by!(date: params[:date], number: params[:number])
    @policy = (Policy.find_by(id: params[:dmp]) || current_user.active_policy)

    new_vote = params["vote#{@policy.id}".to_sym]
    new_vote = nil if new_vote == "--"
    old_vote = @policy.update_division_vote!(@division, new_vote)
    # Return the "changed from" value
    if old_vote != new_vote
      changed_from = old_vote.nil? ? 'non-voter' : old_vote
      changed_to = new_vote.nil? ? 'non-voter' : new_vote
    end
    if changed_from
      # TODO Use the same terminology rather than icky aye3
      flash[:notice] = "Succesfully changed vote on policy from #{changed_from} to #{changed_to}"
    end
    redirect_to view_context.division_path2(@division, display: "policies", dmp: @policy.id)
  end
end

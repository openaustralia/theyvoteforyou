class DivisionsController < ApplicationController
  # TODO: Reenable CSRF protection
  skip_before_action :verify_authenticity_token

  before_action :authenticate_user!, only: [:edit, :update, :add_policy_vote]

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
      @parties = @parties.in_australian_house(@house).joins(:whips).order("pw_cache_whip.party").select(:party).distinct.map{|d| d.party}
    end

    if @rdisplay2 && @rdisplay2 != "rebels"
      if @parties.include? @rdisplay2.gsub('_party', '')
        @party = @rdisplay2.gsub('_party', '')
      else
        @rdisplay2 = nil
      end
    end

    raise "Invalid rdisplay param" unless @rdisplay == "all" || Parliament.all.has_key?(@rdisplay)

    order = case @sort
    when nil
      ["division_date DESC", "clock_time DESC", "division_name", "division_number DESC"]
    when "subject"
      ["division_name", "division_date DESC", "clock_time DESC", "division_number DESC"]
    when "rebellions"
      ["rebellions DESC", "division_date DESC", "clock_time DESC", "division_name", "division_number DESC"]
    when "turnout"
      ["turnout DESC", "division_date DESC", "clock_time DESC", "division_name", "division_number DESC"]
    else
      raise "Unexpected value"
    end

    @divisions = Division.joins(:division_info).order(order)
    @divisions = @divisions.in_australian_house(@house) if @house
    @divisions = @divisions.in_parliament(Parliament.all[@rdisplay]) if @rdisplay != "all"
    @divisions = @divisions.with_rebellions if @rdisplay2 == "rebels"
    @divisions = @divisions.joins(:whips).where(pw_cache_whip: {party: @party}) if @party
  end

  def show
    house = params[:house] || "representatives"
    @sort = params[:sort]
    @display = params[:display]
    @division = Division.in_australian_house(house).find_by!(division_date: params[:date], division_number: params[:number])

    # If a member is included
    if params[:mpn] && params[:mpc]
      first_name = params[:mpn].split("_")[0]
      last_name = params[:mpn].split("_")[1]
      electorate = params[:mpc].gsub("_", " ")
      # TODO Also ensure that the member is current on the date of this division
      member = Member.in_australian_house(house).where(first_name: first_name, last_name: last_name)
      member = member.where(constituency: electorate) if electorate != "Senate"
      member = member.first
      @member = member.member_who_voted_on_division(@division)
    end

    order = case @sort
    when nil, "party"
      ["pw_mp.party", "pw_vote_sortorder.position desc", "pw_mp.last_name", "pw_mp.first_name"]
    when "name"
      ["pw_mp.last_name", "pw_mp.first_name"]
    when "constituency"
      ["pw_mp.constituency", "pw_mp.last_name", "pw_mp.first_name"]
    when "vote"
      ["pw_vote_sortorder.position desc", "pw_mp.last_name", "pw_mp.first_name"]
    else
      raise "Unexpected value"
    end

    if @display.nil?
      # TODO Fix this hacky nonsense by doing this query in the db
      @votes = @division.votes.joins(:member).joins("LEFT JOIN pw_vote_sortorder ON pw_vote_sortorder.vote = pw_vote.vote").order(order).find_all{|v| v.rebellion?}
    elsif @display == "allvotes"
      @votes = @division.votes.joins(:member).joins("LEFT JOIN pw_vote_sortorder ON pw_vote_sortorder.vote = pw_vote.vote").order(order)
    elsif @display == "allpossible"
      @members = Member.in_australian_house(house).current_on(@division.date).joins("LEFT OUTER JOIN pw_vote ON pw_mp.mp_id = pw_vote.mp_id AND pw_vote.division_id = #{@division.id}").joins("LEFT JOIN pw_vote_sortorder ON pw_vote_sortorder.vote = pw_vote.vote").order(order)
    elsif @display == "policies"
      if params[:dmp] || user_signed_in?
        @policy = (Policy.find_by(id: params[:dmp]) || current_user.active_policy)
      end
    else
      raise
    end
  end

  def edit
    @division = Division.in_australian_house(params[:house] || 'representatives').find_by!(division_date: params[:date], division_number: params[:number])
  end

  def show_edits
    @division = Division.in_australian_house(params[:house] || "representatives").find_by!(date: params[:date], number: params[:number])
  end

  def update
    @division = Division.in_australian_house(params[:house] || 'representatives').find_by!(division_date: params[:date], division_number: params[:number])

    # TODO: Provide some feedback to the user about how their save went
    # This is just matching the PHP app right now :(
    if params[:submit] == 'Save'
      @division.create_wiki_motion! params[:newtitle], params[:newdescription], current_user
    end

    params[:rr] ? redirect_to(params[:rr]) : render(:edit)
  end

  def add_policy_vote
    @sort = params[:sort]
    @display = params[:display]
    @division = Division.in_australian_house(params[:house] || "representatives").find_by!(division_date: params[:date], division_number: params[:number])

    @policy = (Policy.find_by(id: params[:dmp]) || current_user.active_policy)
    @changed_from = @policy.add_division(@division, params["vote#{@policy.id}".to_sym])

    render 'show'
  end
end

# encoding: UTF-8

class DivisionsController < ApplicationController
  def index
    @sort = params[:sort]
    @rdisplay = params[:rdisplay]
    @rdisplay = "2010" if @rdisplay.nil?
    @rdisplay2 = params[:rdisplay2]
    @house = params[:house]
    @uk_house = Division.australian_to_uk_house(@house) if @house

    if @rdisplay2 && @rdisplay2 != "rebels"
      @party = @rdisplay2.match(/(.*)_party/)[1]
    end

    parliament = Member.parliaments[@rdisplay]
    raise "Invalid rdisplay param" unless @rdisplay == "all" || Member.parliaments.has_key?(@rdisplay)

    if @rdisplay2 == "rebels"
      @title = "Rebellions"
    elsif @party
      @title = @party
    else
      @title = "Divisions"
    end
    @title += " — "
    @title += @rdisplay == "all" ? "All divisions on record" : parliament[:name]
    if @house == "representatives" && @party.nil?
      @title += " — Representatives only"
    elsif @house == "senate" && @party.nil?
      @title += " — Senate only"
    end
    @title += " (sorted by #{@sort})" if @sort

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
    @divisions = @divisions.in_parliament(parliament) if @rdisplay != "all"    
    @divisions = @divisions.with_rebellions if @rdisplay2 == "rebels"
    @divisions = @divisions.joins(:whips).where(pw_cache_whip: {party: @party}) if @party
  end

  def show
    @house = params[:house]
    @house = "representatives" if @house.nil?
    @uk_house = Division.australian_to_uk_house(@house)
    @date = params[:date]
    @sort = params[:sort]
    @display = params[:display]
    @division = Division.find_by(division_date: @date, division_number: params[:number],
      house: @uk_house)

    # If a member is included
    if params[:mpn] && params[:mpc]
      first_name = params[:mpn].split("_")[0]
      last_name = params[:mpn].split("_")[1]
      electorate = params[:mpc]
      # TODO Also ensure that the member is current on the date of this division
      if electorate == "Senate"
        @member = Member.where(first_name: first_name, last_name: last_name, house: @uk_house).first
      else
        @member = Member.where(first_name: first_name, last_name: last_name, constituency: electorate, house: @uk_house).first
      end
    end

    if @display.nil?
      if @sort.nil?
        @votes = @division.rebellions_order_party
      elsif @sort == "name"
        @votes = @division.rebellions_order_name
      elsif @sort == "vote"
        @votes = @division.rebellions_order_vote
      else
        raise "Unexpected value"
      end
    elsif @display == "allvotes"
      order = case @sort
      when nil, "party"
        ["pw_mp.party", "pw_mp.last_name", "pw_mp.first_name"]
      when "name"
        ["pw_mp.last_name", "pw_mp.first_name"]
      when "vote"
        [:vote, "pw_mp.last_name", "pw_mp.first_name"]
      else
        raise
      end
      @votes = @division.votes.joins(:member).order(order)
    elsif @display == "allpossible"
      order = case @sort
      when nil, "party"
        [:party, "pw_vote_sortorder.position desc", :last_name, :first_name]
      when "name"
        [:last_name, :first_name]
      when "vote"
        ["pw_vote_sortorder.position desc", :last_name, :first_name]
      else
        raise
      end
      @members = Member.where(house: @uk_house).current_on(@date).joins("LEFT OUTER JOIN pw_vote ON pw_mp.mp_id = pw_vote.mp_id AND pw_vote.division_id = #{@division.id}").joins("LEFT JOIN pw_vote_sortorder ON pw_vote_sortorder.vote = pw_vote.vote").order(order)
    elsif @display == "policies"
    else
      raise
    end

    @title = "#{@division.name} — #{@division.date.strftime('%-d %b %Y')}"
    @title += " at #{@division.clock_time.strftime('%H:%M')}" if @division.clock_time
  end
end

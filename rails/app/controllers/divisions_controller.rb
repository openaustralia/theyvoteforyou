# encoding: UTF-8

class DivisionsController < ApplicationController
  def index
    # List of parliaments (temporarily here)
    parliaments = {
      "2010" => {from: Date.new(2010,9,28),  to: Date.new(9999,12,31), name: "2010 (current)"},
      "2007" => {from: Date.new(2008,2,12),  to: Date.new(2010,7,19),  name: "2008-2010"},
      "2004" => {from: Date.new(2004,11,16), to: Date.new(2007,10,17), name: "2004-2007"},
    }

    @sort = params[:sort]
    @rdisplay = params[:rdisplay]
    @rdisplay = "2010" if @rdisplay.nil?
    @rdisplay2 = params[:rdisplay2]
    @house = params[:house]

    parliament = parliaments[@rdisplay]
    raise "Invalid rdisplay param" unless @rdisplay == "all" || parliaments.has_key?(@rdisplay)

    @short_title = @rdisplay2 == "rebels" ? "Rebellions" : "Divisions"
    @short_title += " — "
    @short_title += @rdisplay == "all" ? "All divisions on record" : parliament[:name]
    if @house == "representatives"
      @short_title += " — Representatives only"
    elsif @house == "senate"
      @short_title += " — Senate only"
    end
    @short_title += " (sorted by #{@sort})" if @sort
    @title = @short_title + " — The Public Whip"

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
        [:party, :last_name, :first_name]
      when "name"
        [:last_name, :first_name]
      when "vote"
        ["pw_vote_sortorder.position desc", :last_name, :first_name]
      else
        raise
      end
      @members = Member.where(house: @uk_house).current_on(@date).joins("LEFT OUTER JOIN pw_vote ON pw_vote.mp_id = pw_mp.mp_id").where("pw_vote.division_id = ? OR pw_vote.division_id IS NULL", @division.id).joins("LEFT JOIN pw_vote_sortorder ON pw_vote_sortorder.vote = pw_vote.vote").order(order)
    elsif @display == "policies"
    else
      raise
    end

    if @division.clock_time
      @short_title = "#{@division.name} — #{@division.date.strftime('%d %b %Y')} at #{@division.clock_time.strftime('%H:%M')}"
    else
      @short_title = "#{@division.name} — #{@division.date.strftime('%d %b %Y')}"
    end
    @title = @short_title + " — The Public Whip"

    if @display == "policies"
      render "policies"
    end
  end
end

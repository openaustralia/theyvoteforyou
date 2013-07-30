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
    parliament = parliaments[@rdisplay]
    raise "Invalid rdisplay param" unless @rdisplay == "all" || parliaments.has_key?(@rdisplay)

    @short_title = "Divisions &#8212; ".html_safe
    if @rdisplay == "all"
      @short_title += "All divisions on record".html_safe
    else
      @short_title += "#{parliament[:name]}".html_safe
    end

    @short_title += " (sorted by #{@sort})".html_safe if @sort
    @title = @short_title + " &#8212; The Public Whip".html_safe

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

    if @rdisplay != "all"
      @divisions = @divisions.where("division_date >= ? AND division_date < ?", parliament[:from], parliament[:to])
    end
  end
end

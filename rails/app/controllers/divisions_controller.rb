class DivisionsController < ApplicationController
  def index
    @sort = params[:sort]
    @title = "Divisions &#8212; 2010 (current) &#8212; The Public Whip".html_safe

    @divisions = Division.order("division_date DESC", "clock_time DESC").all
  end
end

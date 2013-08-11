# encoding: UTF-8

class HomeController < ApplicationController
  def index
    @title = "The Public Whip &#8212; ".html_safe
    @divisions = Division.with_rebellions.order("division_date DESC", "clock_time DESC", "division_name", "division_number DESC").limit(5)
  end

  def faq
    @short_title = "Help — Frequently Asked Questions"
    @title = "#{@short_title} — The Public Whip"
  end
end

# encoding: UTF-8

class HomeController < ApplicationController
  def index
    @title = "The Public Whip &#8212; ".html_safe
  end

  def faq
    @short_title = "Help — Frequently Asked Questions"
    @title = "#{@short_title} — The Public Whip"
  end
end

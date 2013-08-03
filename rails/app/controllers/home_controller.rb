# encoding: UTF-8

class HomeController < ApplicationController
  def index
    @title = "The Public Whip &#8212; ".html_safe
  end

  def faq
    @title = "Help — Frequently Asked Questions — The Public Whip"
  end
end

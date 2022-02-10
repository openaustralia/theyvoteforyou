# frozen_string_literal: true

require "open-uri"

class HomeController < ApplicationController
  def index
    @current_members = Member.current.order("last_name")
  end

  def about; end

  def search
    @current_members = Member.current.map { |m| m.name.downcase }
    @mps = []
    @divisions = []

    if params[:query] =~ /^\d{4}$/
      @postcode = params[:query]

      # Temporary work around for https://github.com/openaustralia/openaustralia/issues/502
      json_response = open("https://www.openaustralia.org.au/api/getDivisions?output=js&key=CcV3KBBX2Em7GQeV3RA8qzgS&postcode=#{@postcode}").read
      json_response = "{\"error\":\"Unknown postcode\"}" if json_response == "{\"error\":\"Unknown postcode\"}{}"
      electorates = JSON.parse(json_response)

      if electorates.respond_to?("has_key?") && electorates.key?("error")
        @postcode_error = electorates["error"]
        return
      end

      if electorates.count == 1
        member = Member.current.find_by!(constituency: electorates.first["name"])
        redirect_to view_context.member_path_simple(member)
      elsif electorates.count > 1
        electorates.each do |e|
          member = Member.current_on(Time.zone.today).find_by(constituency: e["name"])
          @mps << member unless member.nil?
        end
      end
    elsif params[:button] == "hero_search" && @current_members.include?(params[:query].downcase)
      redirect_to view_context.member_path_simple(Member.with_name(params[:query]).first)
    elsif params[:query].present?
      res = helpers.senator_search(params[:query])

      if res.empty?
        @mps = Member.search_with_sql_fallback params[:query]
      else
        member = Member.current.where(house: res[0], constituency: res[1])

        member.each do |m|
          @mps << m unless m.nil?
        end

      end

      @divisions = Division.search_with_sql_fallback params[:query]
      @policies = Policy.search_with_sql_fallback params[:query]
    end
  end

  def history
    @history = PaperTrail::Version.where("created_at > ?", 1.week.ago) +
               WikiMotion.where("created_at > ?", 1.week.ago)
    @history.sort_by! { |v| -v.created_at.to_i }
  end

  def error404
    render status: :not_found
  end

  def error500
    render status: :internal_server_error
  end
end

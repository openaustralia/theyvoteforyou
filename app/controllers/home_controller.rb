require 'open-uri'

class HomeController < ApplicationController
  def index
  end

  def about
  end

  def search
    @current_members = Member.current.map { |m| m.name_without_title }
    @mps = []
    @divisions = []

    if params[:query] =~ /^\d{4}$/
      @postcode = params[:query]

      # Temporary work around for https://github.com/openaustralia/openaustralia/issues/502
      json_response = open("http://www.openaustralia.org.au/api/getDivisions?output=js&key=CcV3KBBX2Em7GQeV3RA8qzgS&postcode=#{@postcode}").read
      json_response = "{\"error\":\"Unknown postcode\"}" if json_response == "{\"error\":\"Unknown postcode\"}{}"
      electorates = JSON.parse(json_response)

      if electorates.respond_to?("has_key?") && electorates.has_key?("error")
        @postcode_error = electorates["error"]
        return
      end

      if electorates.count == 1
        member = Member.current.find_by!(constituency: electorates.first['name'])
        redirect_to view_context.member_path(member)
      elsif electorates.count > 1
        electorates.each do |e|
          member = Member.current_on(Date.today).find_by(constituency: e['name'])
          @mps << member unless member.nil?
        end
      end
    elsif params[:button] == "hero_search" && @current_members.include?(params[:query])
      redirect_to view_context.member_path(Member.with_name(params[:query]).first)
    elsif !params[:query].blank?
      @mps = Member.find_by_search_query params[:query]
      @divisions = Division.find_by_search_query params[:query]
      @policies = Policy.find_by_search_query params[:query]
    end
  end

  def history
    @history = PaperTrail::Version.where("created_at > ?", 1.week.ago) +
               WikiMotion.where("edit_date > ?", 1.week.ago)
    @history.sort_by! {|v| -v.created_at.to_i}
  end
end

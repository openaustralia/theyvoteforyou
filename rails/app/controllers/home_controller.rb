require 'open-uri'

class HomeController < ApplicationController
  def index
    @divisions = Division.with_rebellions.order("division_date DESC", "clock_time DESC", "division_name", "division_number DESC").limit(5)
  end

  def faq
  end

  def search
    if params[:query] =~ /^\d{4}$/
      @postcode = params[:query]
      electorates = JSON.parse(open("http://www.openaustralia.org/api/getDivisions?output=js&key=CcV3KBBX2Em7GQeV3RA8qzgS&postcode=#{@postcode}").read)

      if electorates.count == 1
        # FIXME: We should redirect but this is how the PHP app does it currently
        render nothing: true, location: view_context.electorate_path(Member.find_by_constituency(electorates.first['name']))
      elsif electorates.count > 1
        @mps = []
        electorates.each do |e|
          member = Member.find_by_constituency(e['name'])
          @mps << member unless member.nil?
        end
      else
        raise 'No electorates found'
      end
    elsif !params[:query].blank?
      @mps = Member.find_by_search_query params[:query]
      # FIXME: Remove nasty SQL below that was ported from PHP direct
      @divisions = Division.joins('LEFT JOIN pw_cache_divwiki ON pw_cache_divwiki.division_date = pw_division.division_date
                                   AND pw_cache_divwiki.division_number = pw_division.division_number AND pw_cache_divwiki.house = pw_division.house
                                   LEFT JOIN pw_dyn_wiki_motion ON pw_dyn_wiki_motion.wiki_id = pw_cache_divwiki.wiki_id')
                            .where('LOWER(convert(division_name using utf8)) LIKE :query
                                   OR LOWER(convert(motion using utf8)) LIKE :query
                                   OR LOWER(convert(text_body using utf8)) LIKE :query', query: "%#{params[:query]}%")
    end
  end
end

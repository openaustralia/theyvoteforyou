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

      # Temporary work around for https://github.com/openaustralia/openaustralia/issues/502
      json_response = open("http://www.openaustralia.org/api/getDivisions?output=js&key=CcV3KBBX2Em7GQeV3RA8qzgS&postcode=#{@postcode}").read
      json_response = "{\"error\":\"Unknown postcode\"}" if json_response == "{\"error\":\"Unknown postcode\"}{}"
      electorates = JSON.parse(json_response)

      if electorates.respond_to?("has_key?") && electorates.has_key?("error")
        @postcode_error = electorates["error"]
        return
      end

      if electorates.count == 1
        member = Member.find_by_constituency(electorates.first['name'])
        electorate = member ? member.electorate : ''
        # FIXME: We should redirect but this is how the PHP app does it currently
        render nothing: true, status: :found, location: view_context.electorate_path2(electorate)
      elsif electorates.count > 1
        @mps = []
        electorates.each do |e|
          member = Member.find_by_constituency(e['name'])
          @mps << member unless member.nil?
        end
      end
    elsif !params[:query].blank?
      @mps = Member.find_by_search_query params[:query]

      # FIXME: Cargo cult SQL update from PHP's update_divisions_wiki_id() function
      ActiveRecord::Base.connection.execute("INSERT INTO pw_cache_divwiki
                                             (division_date, division_number, house, wiki_id)
                                             SELECT pw_division.division_date AS division_date,
                                                    pw_division.division_number AS division_number,
                                                    pw_division.house AS house,
                                                    IFNULL(MAX(pw_dyn_wiki_motion.wiki_id), -1) AS value
                                             FROM pw_division
                                             LEFT JOIN pw_cache_divwiki ON pw_division.division_date = pw_cache_divwiki.division_date AND
                                                 pw_division.division_number = pw_cache_divwiki.division_number
                                             LEFT JOIN pw_dyn_wiki_motion ON pw_dyn_wiki_motion.division_date = pw_division.division_date
                                                 AND pw_dyn_wiki_motion.division_number = pw_division.division_number
                                                 AND pw_dyn_wiki_motion.house = pw_division.house
                                             WHERE pw_cache_divwiki.wiki_id IS NULL
                                             GROUP BY pw_division.division_id")

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

class DivisionWiki < ActiveRecord::Base
  self.table_name = "pw_cache_divwiki"

  def division
    divisions = Division.where(division_date: division_date,
                               division_number: division_number,
                               house: house).first
  end
end

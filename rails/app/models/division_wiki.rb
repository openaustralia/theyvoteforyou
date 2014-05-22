class DivisionWiki < ActiveRecord::Base
  self.table_name = "pw_cache_divwiki"

  def division
    divisions = Division.find_by(division_date: division_date,
                                 division_number: division_number,
                                 house: house)
  end
end

class DivisionInfo < ActiveRecord::Base
  self.table_name = "pw_cache_divinfo"

  belongs_to :division
end

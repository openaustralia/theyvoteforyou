class Division < ActiveRecord::Base
  self.table_name = "pw_division"

  has_one :division_info
end

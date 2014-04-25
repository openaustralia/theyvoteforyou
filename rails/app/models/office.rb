class Office < ActiveRecord::Base
  self.table_name = "pw_moffice"

  belongs_to :member, foreign_key: :person, primary_key: :person
end

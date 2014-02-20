class User < ActiveRecord::Base
  self.table_name = "pw_dyn_user"

  has_many :wiki_motions
end

class MemberInfo < ActiveRecord::Base
  self.table_name = "pw_cache_mpinfo"

  belongs_to :member, foreign_key: "mp_id"
end

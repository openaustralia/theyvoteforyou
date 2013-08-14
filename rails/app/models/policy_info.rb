class PolicyInfo < ActiveRecord::Base
  self.table_name = 'pw_cache_dreaminfo'
  belongs_to :policy
end

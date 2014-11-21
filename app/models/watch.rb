class Watch < ActiveRecord::Base
  belongs_to :watchable, polymorphic: true
  belongs_to :user
end

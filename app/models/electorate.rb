class Electorate < ActiveRecord::Base
  # TODO Remove this as soon as we can
  alias_attribute :cons_id, :id
end

class Office < ActiveRecord::Base
  # TODO Remove this as soon as we can
  alias_attribute :moffice_id, :id
  
  # TODO make this an association when we can
  def person_object
    Person.new(id: person)
  end
end

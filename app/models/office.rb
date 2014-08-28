class Office < ActiveRecord::Base
  # TODO make this an association when we can
  def person_object
    Person.new(id: person_id)
  end
end

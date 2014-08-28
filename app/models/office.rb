class Office < ActiveRecord::Base
  # TODO make this an association when we can
  def person
    Person.new(id: person_id)
  end
end

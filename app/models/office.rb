class Office < ActiveRecord::Base
  # TODO Remove these as soon as we can
  alias_attribute :moffice_id, :id
  alias_attribute :person, :person_id

  # TODO make this an association when we can
  def person_object
    Person.new(id: person_id)
  end
end

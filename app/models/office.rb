class Office < ActiveRecord::Base
  self.table_name = "pw_moffice"

  # TODO make this an association when we can
  def person_object
    Person.new(id: person)
  end
end

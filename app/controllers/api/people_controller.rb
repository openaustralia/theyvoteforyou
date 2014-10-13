class Api::PeopleController < ApplicationController
  def index
    @people = Person.current
  end
end

class Api::V1::PeopleController < ApplicationController
  def index
    @people = Person.current
  end
end

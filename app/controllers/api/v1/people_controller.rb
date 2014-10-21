class Api::V1::PeopleController < Api::V1::ApplicationController
  def index
    @people = Person.current
  end

  def show
    @person = Person.find(params[:id])
  end
end

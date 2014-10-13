class Api::V1::PeopleController < ApplicationController
  def index
    @people = Person.current
  end

  def show
    @person = Person.find(params[:id])
  end
end

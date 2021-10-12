# frozen_string_literal: true

class Api::V1::PeopleController < Api::V1::ApplicationController
  def index
    @people = Person.current.includes(:members)
  end

  def show
    @person = Person.find(params[:id])
  end
end

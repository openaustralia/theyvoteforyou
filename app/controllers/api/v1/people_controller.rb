# frozen_string_literal: true

module Api
  module V1
    class PeopleController < Api::V1::ApplicationController
      def index
        @people = Person.current.includes(:members)
      end

      def show
        @person = Person.find(params[:id])
      end
    end
  end
end

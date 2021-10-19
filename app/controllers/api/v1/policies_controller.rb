# frozen_string_literal: true

module Api
  module V1
    class PoliciesController < Api::V1::ApplicationController
      def index
        @policies = Policy.order(:id).all
      end

      def show
        @policy = Policy.find(params[:id])
      end
    end
  end
end

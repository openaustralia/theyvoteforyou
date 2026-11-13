# frozen_string_literal: true

module Api
  module V1
    class DivisionsController < Api::V1::ApplicationController
      AI_ASSISTED_FILTERS = { "true" => true, "false" => false, "null" => nil }.freeze

      before_action :check_ai_assisted_filter, only: :index

      def index
        @divisions = Division.order(date: :desc, house: :desc, number: :desc).includes(:wiki_motions, :whips, :division_info).limit(100)
        @divisions = @divisions.where(date: (params[:start_date])..) if params[:start_date]
        @divisions = @divisions.where(date: ..(params[:end_date])) if params[:end_date]
        @divisions = @divisions.where(house: params[:house]) if params[:house]
        @divisions = @divisions.with_ai_assisted(AI_ASSISTED_FILTERS[params[:ai_assisted]]) if ai_assisted_filter?
      end

      def show
        @division = Division.find(params[:id])
      end

      private

      # The filter only exists while the feature is on. "null" is the literal string, as a query string can't
      # carry a real null.
      def ai_assisted_filter?
        ai_disclosure_public? && params.key?(:ai_assisted)
      end

      def check_ai_assisted_filter
        return if !ai_assisted_filter? || AI_ASSISTED_FILTERS.key?(params[:ai_assisted])

        render json: { error: "ai_assisted must be true, false or null" }, status: :bad_request
      end
    end
  end
end

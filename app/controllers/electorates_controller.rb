# frozen_string_literal: true

class ElectoratesController < ApplicationController
  def show_redirect
    redirect_to params.to_unsafe_hash.merge(only_path: true, display: nil, dmp: nil, house: (params[:house] || "representatives"))
  end
end

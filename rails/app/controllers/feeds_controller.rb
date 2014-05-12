class FeedsController < ApplicationController
  def mp_info
    @members = Member.all.order(:entered_house, :last_name, :first_name, :constituency)
  end
end

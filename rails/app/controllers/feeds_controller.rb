class FeedsController < ApplicationController
  def mp_info
    # FIXME: We should change the accepted value to senate instead of lords
    house =  params[:house] == 'lords' ? 'senate' : 'representatives'
    @members = Member.in_australian_house(house).order(:entered_house, :last_name, :first_name, :constituency)
    @most_recent_division = Division.most_recent_date
  end

  def mpdream_info; end
end

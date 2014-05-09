class PoliciesController < ApplicationController
  def index
    @policies = Policy.joins(:policy_info).order(:private, :name)
  end

  def show
    @policy = Policy.find(params[:id])
    @display = params[:display]

    if @display == 'editdefinition' && !user_signed_in?
      redirect_to controller: 'account',
                  action: 'settings',
                  params: { r: policy_path(id: @policy.id, display: 'editdefinition') }
    end
  end
end

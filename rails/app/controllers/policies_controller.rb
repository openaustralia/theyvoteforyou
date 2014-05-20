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

  # FIXME: Make this more RESTful
  def add
    redirect_to action: 'settings', params: { r: '/account/addpolicy.php' } unless user_signed_in?

    if params[:submit]
      @policy = Policy.create name: params[:name], description: params[:description], user: current_user, private: 2
    end
  end
end

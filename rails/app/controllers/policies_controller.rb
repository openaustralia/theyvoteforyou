class PoliciesController < ApplicationController
  # TODO: Reenable CSRF protection
  skip_before_action :verify_authenticity_token

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

  def new
    redirect_to action: 'settings', params: { r: '/account/addpolicy.php' } unless user_signed_in?
  end

  def create
    redirect_to action: 'settings', params: { r: '/account/addpolicy.php' } unless user_signed_in?

    @policy = Policy.new name: params[:name], description: params[:description], user: current_user, private: 2
    render 'new' unless @policy.save!
  end
end

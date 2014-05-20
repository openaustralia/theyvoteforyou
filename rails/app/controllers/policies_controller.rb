class PoliciesController < ApplicationController
  # TODO: Reenable CSRF protection
  skip_before_action :verify_authenticity_token

  before_filter :check_user_signed_in, only: [:new, :create]

  def index
    @policies = Policy.joins(:policy_info).order(:private, :name)
  end

  def show
    @policy = Policy.find(params[:id])
    @display = params[:display]

    # TODO: Extract into check_user_signed_in method
    if @display == 'editdefinition' && !user_signed_in?
      redirect_to controller: 'account',
                  action: 'settings',
                  params: { r: policy_path(id: @policy.id, display: 'editdefinition') }
    end
  end

  def new
  end

  def create
    @policy = Policy.new name: params[:name], description: params[:description], user: current_user, private: 2
    render 'new' unless @policy.save!
  end

  private

  def check_user_signed_in
    redirect_to controller: 'account', action: 'settings', params: { r: '/account/addpolicy.php' } unless user_signed_in?
  end
end

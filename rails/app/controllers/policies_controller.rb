class PoliciesController < ApplicationController
  # TODO: Reenable CSRF protection
  skip_before_action :verify_authenticity_token

  before_action :authenticate_user!, only: [:new, :create]

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
    elsif @display == 'editdefinition' && user_signed_in?
      # FIXME This is how the user sets their active policy in PHP which is silly for many reasons
      current_user.update_attribute :active_policy_id, @policy.id
    end
  end

  def new
  end

  def create
    @policy = Policy.new name: params[:name], description: params[:description], user: current_user, private: 2
    render 'new' unless @policy.save
  end
end

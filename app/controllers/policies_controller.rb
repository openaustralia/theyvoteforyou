class PoliciesController < ApplicationController
  # TODO: Reenable CSRF protection
  skip_before_action :verify_authenticity_token

  before_action :authenticate_user!, except: [:index, :show, :detail]

  def index
    @policies = Policy.order(:private, :name).includes(:divisions => :wiki_motions)
  end

  def show
    @policy = Policy.find(params[:id])
  end

  def detail
    @policy = Policy.find(params[:id])
  end

  def edit
    @policy = Policy.find(params[:id])

    # FIXME This is how the user sets their active policy in PHP which is silly for many reasons
    current_user.update_attribute :active_policy_id, @policy.id
  end

  def new
  end

  def create
    @policy = Policy.new name: params[:name], description: params[:description], user: current_user, private: 2
    render 'new' unless @policy.save
  end

  def update
    @policy = Policy.find(params[:id])
    # FIXME: In PHP it silently ignores empty attributes, we should show an error
    @policy.update_attributes!({name: params[:name], description: params[:description], private: (params[:provisional] ? 2 : 0)}.reject { |k,v| v.blank? })
    redirect_to action: 'show', id: @policy
  end

  def history
    @policy = Policy.find(params[:id])
  end
end

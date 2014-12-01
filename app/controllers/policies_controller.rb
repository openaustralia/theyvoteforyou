class PoliciesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :drafts, :show, :detail, :full, :history]

  def index
    @policies = Policy.visible.order(:name)
  end

  def drafts
    @policies = Policy.provisional.order(:name)
  end

  def show
    @policy = Policy.find(params[:id])

    if params[:mpc] && params[:mpn]
      electorate = params[:mpc].gsub("_", " ")
      name = params[:mpn].gsub("_", " ")

      @member = Member.with_name(name)
      @member = @member.in_house(params[:house])
      @member = @member.where(constituency: electorate)
      @member = @member.order(entered_house: :desc).first

      if @member
        # Pick the member where the votes took place
        @member = @member.person.member_for_policy(@policy)
        render "show_with_member"
      else
        render 'members/member_not_found', status: 404
      end
    end
  end

  def detail
    @policy = Policy.find(params[:id])
  end

  def edit
    @policy = Policy.find(params[:id])
  end

  def new
    @policy = Policy.new
  end

  def create
    @policy = Policy.new name: params[:policy][:name], description: params[:policy][:description], user: current_user, private: 2
    if @policy.save
      redirect_to @policy, notice: 'Successfully made new policy'
    else
      flash[:alert] = 'Creating a new policy not complete, please try again'
      render 'new'
    end
  end

  def update
    @policy = Policy.find(params[:id])

    if @policy.update name: params[:name], description: params[:description], private: (params[:provisional] ? 2 : 0)
      @policy.alert_watches(@policy.versions.last)
      redirect_to @policy, notice: 'Policy updated.'
    else
      redirect_to edit_policy_path(@policy), alert: 'Could not update policy.'
    end
  end

  def history
    @policy = Policy.find(params[:id])
    @history = PaperTrail::Version.where(policy_id: @policy.id).order(created_at: :desc)
  end

  def watch
    @policy = Policy.find(params[:id])
    current_user.toggle_policy_watch(@policy)
    if !current_user.watching?(@policy)
      flash[:notice] = 'Unsubscribed from email alerts'
    end
    redirect_to :back
  end
end

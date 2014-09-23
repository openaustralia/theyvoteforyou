class PoliciesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :detail, :full]

  def index
    @policies = Policy.order(:private, :name).includes(:divisions => :wiki_motions)
  end

  def show
    @policy = Policy.find(params[:id])

    if params[:mpc] && params[:mpn]
      electorate = params[:mpc].gsub("_", " ")
      name = params[:mpn].gsub("_", " ")

      @member = Member.with_name(name)
      @member = @member.in_australian_house(params[:house])
      @member = @member.where(constituency: electorate)
      @member = @member.order(entered_house: :desc).first

      if @member
        # Pick the member where the votes took place
        @member = @member.person.member_for_policy(@policy)
        render "members/policy"
      else
        render 'members/member_not_found', status: 404
      end
    end
  end

  def full
    electorate = params[:mpc].gsub("_", " ")
    name = params[:mpn].gsub("_", " ")
    @full = true

    @member = Member.with_name(name)
    @member = @member.in_australian_house(params[:house])
    @member = @member.where(constituency: electorate)
    @member = @member.order(entered_house: :desc).first

    if @member
      @policy = Policy.find(params[:id])
      # Pick the member where the votes took place
      @member = @member.person.member_for_policy(@policy)
      render "members/policy"
    else
      render 'members/member_not_found', status: 404
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

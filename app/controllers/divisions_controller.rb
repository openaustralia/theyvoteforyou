# frozen_string_literal: true

class DivisionsController < ApplicationController
  before_action :authenticate_user!, only: %i[edit update show_policies create_policy_division update_policy_division destroy_policy_division]

  def index
    @years = (Division.order(:date).first.date.year..Division.order(:date).last.date.year).to_a

    begin
      @date_start, @date_end, @date_range = date_range(params[:date])
    rescue ArgumentError
      return render "home/error404", status: :not_found
    end

    @house = params[:house] unless params[:house] == "all"
    raise ActiveRecord::RecordNotFound if @house && !House.valid?(@house)

    @sort = params[:sort]

    order = case @sort
            when "subject"
              ["name", "date DESC", "clock_time DESC", "number DESC"]
            when "rebellions"
              ["rebellions DESC", "date DESC", "clock_time DESC", "name", "number DESC"]
            when "turnout"
              ["turnout DESC", "date DESC", "clock_time DESC", "name", "number DESC"]
            else
              @sort = nil
              ["date DESC", "clock_time DESC", "name", "number DESC"]
            end

    @divisions = Division.order(order)
    @divisions = @divisions.joins(:division_info) if @sort == "rebellions" || @sort == "turnout"
    @divisions = @divisions.in_house(@house) if @house
    @divisions = @divisions.in_date_range(@date_start, @date_end)
    @divisions = @divisions.includes(:division_info, :wiki_motions, :whips)
  end

  def index_with_member
    @years = (Division.order(:date).first.date.year..Division.order(:date).last.date.year).to_a

    begin
      @date_start, @date_end, @date_range = date_range(params[:date])
    rescue ArgumentError
      return render "home/error404", status: :not_found
    end

    @house = params[:house]
    raise ActiveRecord::RecordNotFound unless House.valid?(@house)

    @member = Member.find_with_url_params(house: @house, mpc: params[:mpc], mpn: params[:mpn])
    return render "members/member_not_found", status: :not_found if @member.nil?

    canonical_member = @member.person.latest_member
    if canonical_member != @member
      return redirect_to member_divisions_url(
        house: canonical_member.house,
        mpc: canonical_member.url_electorate.downcase,
        mpn: canonical_member.url_name.downcase,
        date: params[:date]
      )
    end

    @divisions = @member.divisions_they_could_have_attended_between(@date_start, @date_end)
    @divisions = @divisions.includes(:division_info, :wiki_motions, :whips)
  end

  def show
    house = params[:house]
    date = params[:date]
    number = params[:number]

    @division = division(house, date, number)

    if @division.nil?
      render "home/error404", status: :not_found
    else
      @rebellions = @division.votes.rebellious.order("members.last_name", "members.first_name") if @division.rebellions.positive?
      @whips = @division.whips.order(:party)
      @votes = @division.votes.joins(:member).includes(:member).order("members.party", "vote", "members.last_name", "members.first_name")

      @members = Member.in_house(house).current_on(@division.date)
                       .joins("LEFT OUTER JOIN votes ON members.id = votes.member_id AND votes.division_id = #{@division.id}")
                       .order("members.party", "vote", "members.last_name", "members.first_name")

      @members_vote_null = @members.where(votes: { id: nil })
    end
  end

  def show_policies
    @division = Division.in_house(params[:house]).find_by!(date: params[:date], number: params[:number])
    @policy_division = @division.policy_divisions.new
  end

  def edit
    @division = Division.in_house(params[:house] || "representatives").find_by!(date: params[:date], number: params[:number])
    authorize @division
  end

  def history
    @division = Division.in_house(params[:house] || "representatives").find_by!(date: params[:date], number: params[:number])
  end

  def update
    @division = Division.in_house(params[:house] || "representatives").find_by!(date: params[:date], number: params[:number])
    authorize @division

    wiki_motion = @division.build_wiki_motion(params[:newtitle], params[:newdescription], current_user)

    if wiki_motion.save
      redirect_to view_context.division_path_simple(@division), notice: "Division updated"
    else
      redirect_to view_context.edit_division_path_simple(@division), alert: "Could not update division"
    end
  end

  # TODO: Move this to a policy_division controller
  def create_policy_division
    @division = Division.in_house(params[:house]).find_by!(date: params[:date], number: params[:number])
    @policy_division = @division.policy_divisions.new(policy_division_params)
    authorize @policy_division, :create?

    if @policy_division.save
      # TODO: Just point to the object when the path helper has been refactored
      redirect_to division_policies_path(house: @division.house, date: @division.date, number: @division.number)
    else
      flash[:error] = "Could not connect policy"
      @display = "policies"
      render "show_policies"
    end
  end

  # TODO: Move this to a policy_division controller
  def update_policy_division
    division = Division.in_house(params[:house]).find_by!(date: params[:date], number: params[:number])
    policy_division = PolicyDivision.find_by!(division: division, policy: params[:policy_id])
    authorize policy_division, :update?

    if policy_division.update(policy_division_params)
      flash[:notice] = "Updated policy connection"
    else
      flash[:error] = "Could not update policy connection"
    end

    # TODO: Just point to the object when the path helper has been refactored
    redirect_to division_policies_path(house: division.house, date: division.date, number: division.number)
  end

  # TODO: Move this to a policy_division controller
  def destroy_policy_division
    division = Division.in_house(params[:house]).find_by!(date: params[:date], number: params[:number])
    policy_division = PolicyDivision.find_by!(division: division, policy: params[:policy_id])
    authorize policy_division, :destroy?

    if policy_division.destroy
      flash[:notice] = "Removed policy connection"
    else
      flash[:error] = "Could not remove policy connection"
    end

    # TODO: Just point to the object when the path helper has been refactored
    redirect_to division_policies_path(house: division.house, date: division.date, number: division.number)
  end

  private

  def policy_division_params
    params.require(:policy_division).permit(:policy_id, :vote)
  end

  def date_range(date)
    DivisionParameterParser.date_range(date || @years.last.to_s)
  end

  def division(house, date, number)
    Division.in_house(house)
            .joins(:division_info, :whips)
            .includes(:division_info, :whips)
            .find_by(date: date, number: number)
  end
end

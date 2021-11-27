# frozen_string_literal: true

class MembersController < ApplicationController
  def index
    @sort = params[:sort]
    @house = params[:house]

    members = Member.current
    if @house
      raise ActiveRecord::RecordNotFound unless House.australian.include?(@house)

      members = members.in_house(@house)
    end
    members = members.includes(:member_info, person: [members: :member_info]).to_a

    @members = case @sort
               when "constituency"
                 members.sort_by { |m| [m.constituency, m.last_name, m.first_name, m.party, -m.entered_house.to_time.to_i] }
               when "party"
                 members.sort_by { |m| [m.party, m.last_name, m.first_name, m.constituency, -m.entered_house.to_time.to_i] }
               when "rebellions"
                 members.sort_by { |m| [-(m.person.rebellions_fraction || -1), m.last_name, m.first_name, m.constituency, m.party, -m.entered_house.to_time.to_i] }
               when "attendance"
                 members.sort_by { |m| [-(m.person.attendance_fraction || -1), m.last_name, m.first_name, m.constituency, m.party, -m.entered_house.to_time.to_i] }
               else
                 members.sort_by { |m| [m.last_name, m.first_name, m.constituency, m.party, -m.entered_house.to_time.to_i] }
               end
  end

  def show_redirect
    member = if params[:mpid]
               Member.find_by!(id: params[:mpid])
             elsif params[:id]
               begin
                 Member.find_by!(gid: params[:id])
               rescue ActiveRecord::RecordNotFound
                 Member.find_by!(gid: params[:id].gsub(/member/, "lord"))
               end
             else
               raise
             end
    if params[:dmp]
      redirect_to member_policy_url(
        house: member.house,
        mpc: member.url_electorate.downcase,
        mpn: member.url_name.downcase,
        id: params[:dmp]
      )
    else
      redirect_to member_url(
        house: member.house,
        mpc: member.url_electorate.downcase,
        mpn: member.url_name.downcase
      )
    end
  end

  def friends
    electorate = params[:mpc].gsub("_", " ")
    name = params[:mpn].gsub("_", " ")

    @member = Member.with_name(name)
    @member = @member.in_house(params[:house])
    @member = @member.where(constituency: electorate)
    @member = @member.order(entered_house: :desc).first

    return render "member_not_found", status: :not_found if @member.nil?

    canonical_member = @member.person.latest_member
    return if canonical_member == @member

    redirect_to friends_member_url(
      house: canonical_member.house,
      mpc: canonical_member.url_electorate.downcase,
      mpn: canonical_member.url_name.downcase
    )
  end

  def show
    electorate = params[:mpc].gsub("_", " ")
    name = params[:mpn].gsub("_", " ")

    @member = Member.with_name(name)
    @member = @member.in_house(params[:house])
    @member = @member.where(constituency: electorate)
    @member = @member.order(entered_house: :desc).first

    return render "member_not_found", status: :not_found if @member.nil?

    canonical_member = @member.person.latest_member
    return if canonical_member == @member

    redirect_to member_url(
      house: canonical_member.house,
      mpc: canonical_member.url_electorate.downcase,
      mpn: canonical_member.url_name.downcase
    )
  end

  def policy
    @policy = Policy.find(params[:id])

    electorate = params[:mpc].gsub("_", " ")
    name = params[:mpn].gsub("_", " ")

    @member = Member.with_name(name)
    @member = @member.in_house(params[:house])
    @member = @member.where(constituency: electorate)
    @member = @member.order(entered_house: :desc).first

    return render "member_not_found", status: :not_found if @member.nil?

    canonical_member = @member.person.latest_member
    if canonical_member != @member
      return redirect_to member_policy_url(
        house: canonical_member.house,
        mpc: canonical_member.url_electorate.downcase,
        mpn: canonical_member.url_name.downcase,
        id: params[:id]
      )
    end

    # Pick the member where the votes took place
    @member = @member.person.member_for_policy(@policy)
    render "policies/show_with_member"
  end

  def compare
    electorate1 = params[:mpc].gsub("_", " ")
    electorate2 = params[:mpc2].gsub("_", " ")
    name1 = params[:mpn].gsub("_", " ")
    name2 = params[:mpn2].gsub("_", " ")

    @member1 = Member.with_name(name1)
    @member1 = @member1.in_house(params[:house])
    @member1 = @member1.where(constituency: electorate1)
    @member1 = @member1.order(entered_house: :desc).first

    @member2 = Member.with_name(name2)
    @member2 = @member2.in_house(params[:house])
    @member2 = @member2.where(constituency: electorate2)
    @member2 = @member2.order(entered_house: :desc).first

    return render "member_not_found", status: :not_found if @member1.nil? || @member2.nil?

    canonical_member1 = @member1.person.latest_member
    canonical_member2 = @member2.person.latest_member
    if canonical_member1 != @member1 || canonical_member2 != @member2
      redirect_to compare_member_url(
        house: canonical_member1.house,
        mpc: canonical_member1.url_electorate.downcase,
        mpn: canonical_member1.url_name.downcase,
        mpc2: canonical_member2.url_electorate.downcase,
        mpn2: canonical_member2.url_name.downcase
      )
      return
    end

    @policies = []
    @member1.person.policy_person_distances.published.each do |ppd1|
      # TODO: This is very inefficient. Doing many database lookups
      ppd2 = ppd1.policy.policy_person_distances.find_by(person_id: @member2.person.id)

      # Don't consider policies for which either member didn't vote
      next if ppd2.nil? || !ppd1.voted? || !ppd2.voted?

      @policies << {
        policy: ppd1.policy,
        ppd1: ppd1,
        ppd2: ppd2,
        difference: (ppd1.agreement_fraction - ppd2.agreement_fraction).abs
      }
    end
    @policies = @policies.sort_by { |p| p[:difference] }.reverse
  end
end

# frozen_string_literal: true

class MembersController < ApplicationController
  before_action :find_member_and_redirect_to_canonical, only: %i[show policy friends]

  def index
    @sort = params[:sort]
    @house = params[:house]

    members = Member.current
    if @house
      raise ActiveRecord::RecordNotFound unless House.australian.include?(@house)

      members = members.in_house(@house)
    end
    members = members.includes(:member_info, person: [members: :member_info]).to_a

    members = case @sort
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
    @people = members.map(&:person)
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
               raise ActiveRecord::RecordNotFound
             end
    if params[:dmp]
      redirect_to member_policy_url(helpers.member_params(member).merge(id: params[:dmp]))
    else
      redirect_to member_url(helpers.member_params(member))
    end
  end

  def friends; end

  def show; end

  def policy
    @policy = Policy.find(params[:id])

    # Pick the member where the votes took place
    @member = @member.person.member_for_policy(@policy)
    # TODO: Ideally the view template below should only need @policy_person_distance not @policy and @member
    # If policy_person_distance doesn't exist then return a 404
    @policy_person_distance = @member.person.policy_person_distances.find_by!(policy: @policy)

    render "policies/show_with_member"
  end

  def compare
    @member1 = Member.find_with_url_params(house: params[:house], mpc: params[:mpc], mpn: params[:mpn])
    @member2 = Member.find_with_url_params(house: params[:house], mpc: params[:mpc2], mpn: params[:mpn2])
    return render "member_not_found", status: :not_found if @member1.nil? || @member2.nil?

    canonical_member1 = @member1.person.latest_member
    canonical_member2 = @member2.person.latest_member
    if canonical_member1 != @member1 || canonical_member2 != @member2
      redirect_to helpers.member_params(canonical_member1).merge(
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

  private

  def find_member_and_redirect_to_canonical
    @member = Member.find_with_url_params(house: params[:house], mpc: params[:mpc], mpn: params[:mpn])
    return render "member_not_found", status: :not_found if @member.nil?

    canonical_member = @member.person.latest_member
    return if canonical_member == @member

    redirect_to helpers.member_params(canonical_member)
  end
end

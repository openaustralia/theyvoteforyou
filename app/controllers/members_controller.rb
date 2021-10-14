# frozen_string_literal: true

class MembersController < ApplicationController
  def index_redirect
    redirect_to members_path(
      house: (params[:house] && params[:house] != "all" ? params[:house] : "representatives"),
      sort: (params[:sort] if params[:sort] != "lastname")
    )
  end

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
    if params[:mpid] || params[:id] || params[:mpc] == "Senate" || params[:mpc].nil? || params[:house].nil?
      if params[:mpid]
        member = Member.find_by!(id: params[:mpid])
      elsif params[:id]
        member = begin
          Member.find_by!(gid: params[:id])
        rescue ActiveRecord::RecordNotFound
          Member.find_by!(gid: params[:id].gsub(/member/, "lord"))
        end
      elsif params[:mpc] == "Senate" || params[:mpc].nil? || params[:house].nil?
        member = Member.with_name(params[:mpn].gsub("_", " "))
        member = member.in_house(params[:house]) if params[:house]
        member = member.order(entered_house: :desc).first
        if member.nil?
          render "member_not_found", status: 404
          return
        end
      end
      redirect_to params.to_unsafe_hash.merge(
        only_path: true,
        mpn: member.url_name,
        mpc: member.url_electorate,
        house: member.house,
        mpid: nil,
        id: nil
      )
      return
    end
    if params[:dmp] && params[:display] == "allvotes"
      redirect_to params.to_unsafe_hash.merge(only_path: true, display: nil)
      return
    end
    if params[:display] == "summary" || params[:display] == "alldreams"
      redirect_to params.to_unsafe_hash.merge(only_path: true, display: nil)
      return
    end
    redirect_to params.to_unsafe_hash.merge(only_path: true, showall: nil, display: "everyvote") if params[:display] == "allvotes" || params[:showall] == "yes"
  end

  def friends
    electorate = params[:mpc].gsub("_", " ")
    name = params[:mpn].gsub("_", " ")

    @member = Member.with_name(name)
    @member = @member.in_house(params[:house])
    @member = @member.where(constituency: electorate)
    @member = @member.order(entered_house: :desc).first

    render "member_not_found", status: 404 if @member.nil?
  end

  def show
    electorate = params[:mpc].gsub("_", " ")
    name = params[:mpn].gsub("_", " ")

    @member = Member.with_name(name)
    @member = @member.in_house(params[:house])
    @member = @member.where(constituency: electorate)
    @member = @member.order(entered_house: :desc).first

    render "member_not_found", status: 404 if @member.nil?
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

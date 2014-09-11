class MembersController < ApplicationController
  def index_redirect
    redirect_to members_path(
      house: (params[:house] && params[:house] != "all" ? params[:house] : "representatives"),
      sort: (params[:sort] if params[:sort] != "lastname"))
  end

  def index
    @sort = params[:sort]
    @house = params[:house]

    members = Member.in_australian_house(@house).current.includes(:member_info).to_a

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
        member = Member.find_by!(gid: params[:id])
      elsif params[:mpc] == "Senate" || params[:mpc].nil? || params[:house].nil?
        member = Member.with_name(params[:mpn].gsub("_", " "))
        member = member.in_australian_house(params[:house]) if params[:house]
        member = member.order(entered_house: :desc).first
        if member.nil?
          render 'member_not_found', status: 404
          return
        end
      end
      redirect_to params.merge(
          mpn: member.url_name,
          mpc: member.url_electorate,
          house: member.australian_house,
          mpid: nil,
          id: nil
        )
      return
    end
    if params[:dmp] && params[:display] == "allvotes"
      redirect_to params.merge(display: nil)
      return
    end
    if params[:display] == "summary" || params[:display] == "alldreams"
      redirect_to params.merge(display: nil)
      return
    end
    if params[:display] == "allvotes" || params[:showall] == "yes"
      redirect_to params.merge(showall: nil, display: "everyvote")
    end
  end

  def friends
    electorate = params[:mpc].gsub("_", " ")
    name = params[:mpn].gsub("_", " ")

    @member = Member.with_name(name)
    @member = @member.in_australian_house(params[:house])
    @member = @member.where(constituency: electorate)
    @member = @member.order(entered_house: :desc).first

    if @member.nil?
      render 'member_not_found', status: 404
      return
    end
    members = Member.where(person_id: @member.person_id).order(entered_house: :desc)
    # Trying this hack. Seems mighty weird
    # TODO Get rid of this
    @member = members.first if @member.senator?
  end

  def votes
    electorate = params[:mpc].gsub("_", " ")
    name = params[:mpn].gsub("_", " ")

    @member = Member.with_name(name)
    @member = @member.in_australian_house(params[:house])
    @member = @member.where(constituency: electorate)
    @member = @member.order(entered_house: :desc).first

    if @member.nil?
      render 'member_not_found', status: 404
      return
    end
    @members = Member.where(person_id: @member.person_id).order(entered_house: :desc)
    # Trying this hack. Seems mighty weird
    # TODO Get rid of this
    @member = @members.first if @member.senator?
  end

  def full
    electorate = params[:mpc].gsub("_", " ")
    name = params[:mpn].gsub("_", " ")
    @full = true

    @member = Member.with_name(name)
    @member = @member.in_australian_house(params[:house])
    @member = @member.where(constituency: electorate)
    @member = @member.order(entered_house: :desc).first

    if @member.nil?
      render 'member_not_found', status: 404
      return
    end

    @policy = Policy.find(params[:dmp])
    # Pick the member where the votes took place
    @member = @member.person.member_for_policy(@policy)
    render "show_policy"
  end

  def policy
    electorate = params[:mpc].gsub("_", " ")
    name = params[:mpn].gsub("_", " ")

    @member = Member.with_name(name)
    @member = @member.in_australian_house(params[:house])
    @member = @member.where(constituency: electorate)
    @member = @member.order(entered_house: :desc).first

    if @member.nil?
      render 'member_not_found', status: 404
      return
    end

    @policy = Policy.find(params[:dmp])
    # Pick the member where the votes took place
    @member = @member.person.member_for_policy(@policy)
    render "show_policy"
  end

  def show
    electorate = params[:mpc].gsub("_", " ")
    name = params[:mpn].gsub("_", " ")

    @member = Member.with_name(name)
    @member = @member.in_australian_house(params[:house])
    @member = @member.where(constituency: electorate)
    @member = @member.order(entered_house: :desc).first

    if @member.nil?
      render 'member_not_found', status: 404
      return
    end

    @members = Member.where(person_id: @member.person_id).order(entered_house: :desc)
    # Trying this hack. Seems mighty weird
    # TODO Get rid of this
    @member = @members.first if @member.senator?
    render "show"
  end
end

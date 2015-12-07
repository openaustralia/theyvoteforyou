class MembersController < ApplicationController
  def index_redirect
    redirect_to members_path(
      house: (params[:house] && params[:house] != "all" ? params[:house] : "representatives"),
      sort: (params[:sort] if params[:sort] != "lastname"))
  end

  def index
    @sort = params[:sort]
    @house = params[:house]

    members = Member.current
    if @house
      raise ActiveRecord::RecordNotFound unless House.valid?(@house)
      members = members.in_house(@house)
    end
    members = members.includes(:member_info, person: [members: :member_info] ).to_a

    @members = case @sort
    when "constituency"
      members.sort_by { |m| [I18n.transliterate(m.constituency), I18n.transliterate(m.last_name), I18n.transliterate(m.first_name), I18n.transliterate(m.party), -m.entered_house.to_time.to_i] }
    when "party"
      members.sort_by { |m| [I18n.transliterate(m.party), I18n.transliterate(m.last_name), I18n.transliterate(m.first_name), I18n.transliterate(m.constituency), -m.entered_house.to_time.to_i] }
    when "rebellions"
      members.sort_by { |m| [-(m.person.rebellions_fraction || -1), I18n.transliterate(m.last_name), I18n.transliterate(m.first_name), I18n.transliterate(m.constituency), I18n.transliterate(m.party), -m.entered_house.to_time.to_i] }
    when "attendance"
      members.sort_by { |m| [-(m.person.attendance_fraction || -1), I18n.transliterate(m.last_name), I18n.transliterate(m.first_name), I18n.transliterate(m.constituency), I18n.transliterate(m.party), -m.entered_house.to_time.to_i] }
    else
      members.sort_by { |m| [I18n.transliterate(m.last_name), I18n.transliterate(m.first_name), I18n.transliterate(m.constituency), I18n.transliterate(m.party), -m.entered_house.to_time.to_i] }
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
        member = member.in_house(params[:house]) if params[:house]
        member = member.order(entered_house: :desc).first
        if member.nil?
          render 'member_not_found', status: 404
          return
        end
      end
      redirect_to params.merge(
          only_path: true,
          mpn: member.url_name,
          mpc: member.url_electorate,
          house: member.house,
          mpid: nil,
          id: nil
        ).to_h
      return
    end
    if params[:dmp] && params[:display] == "allvotes"
      redirect_to params.merge(only_path: true, display: nil).to_h
      return
    end
    if params[:display] == "summary" || params[:display] == "alldreams"
      redirect_to params.merge(only_path: true, display: nil).to_h
      return
    end
    if params[:display] == "allvotes" || params[:showall] == "yes"
      redirect_to params.merge(only_path: true, showall: nil, display: "everyvote").to_h
    end
  end

  def friends
    electorate = params[:mpc].gsub("_", " ")
    name = params[:mpn].gsub("_", " ")

    @member = Member.with_name(name)
    @member = @member.in_house(params[:house])
    @member = @member.where(constituency: electorate)
    @member = @member.order(entered_house: :desc).first

    render 'member_not_found', status: 404 if @member.nil?
  end

  def show
    name = params[:mpn].gsub("_", " ")
    electorate = electorate_param

    @member = Member.with_name(name)
    @member = @member.in_house(params[:house])
    @member = @member.where(constituency: electorate)
    @member = @member.order(entered_house: :desc).first

    render 'member_not_found', status: 404 if @member.nil?
  end
end

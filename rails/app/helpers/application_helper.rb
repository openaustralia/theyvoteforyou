module ApplicationHelper
  def member_path(member)
    "mp.php?mpn=#{member.url_name}&mpc=#{member.electorate}&house=#{member.australian_house}"
  end

  def electorate_path(member)
    "mp.php?mpc=#{member.electorate}"
  end
end

module ApplicationHelper
  def member_path(member)
    if member.senator?
      # TODO Seems odd to me the mpc=Senate would expect mpc=Tasmania
      "mp.php?mpn=#{member.url_name}&mpc=Senate&house=#{member.australian_house}"
    else
      "mp.php?mpn=#{member.url_name}&mpc=#{member.electorate}&house=#{member.australian_house}"
    end
  end

  def electorate_path(member)
    "mp.php?mpc=#{member.electorate}"
  end
end

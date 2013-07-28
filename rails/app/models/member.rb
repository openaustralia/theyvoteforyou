class Member < ActiveRecord::Base
  self.table_name = "pw_mp"
  has_one :member_info, foreign_key: "mp_id"

  def name
    "#{first_name} #{last_name}"
  end

  def url_name
    name.gsub(" ", "_")
  end

  def australian_house
    case house
    when "commons"
      "representatives"
    when "lords"
      "senate"
    else
      raise "Unexpected house"
    end
  end

  def electorate
    constituency
  end
end

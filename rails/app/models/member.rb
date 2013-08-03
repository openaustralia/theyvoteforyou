class Member < ActiveRecord::Base
  self.table_name = "pw_mp"
  has_one :member_info, foreign_key: "mp_id"
  delegate :rebellions, :votes_attended, :votes_possible, to: :member_info
  has_many :offices, foreign_key: "person", primary_key: "person"

  def name
    "#{title} #{first_name} #{last_name}".strip
  end

  def offices_on_date(date)
    offices.where("? >= from_date AND ? <= to_date", date, date)
  end

  # TODO This is wrong as parliamentary secretaries will be considered to be on the
  # front bench which as far as I understand is not the case
  def on_front_bench?(date)
    !offices_on_date(date).empty?
  end

  def last_name
    # For some reason some characters are stored in the database using html entities
    # rather than using unicode.
    HTMLEntities.new.decode(read_attribute(:last_name))
  end

  def constituency
    # For some reason some characters are stored in the database using html entities
    # rather than using unicode.
    HTMLEntities.new.decode(read_attribute(:constituency))
  end

  # Long version of party name
  def party_long
    case party
    when "SPK"
      "Speaker"
    when "CWM"
      "Deputy Speaker"
    when "PRES"
      "President"
    when "DPRES"
      "Deputy President"
    else
      party
    end
  end

  # Also say "whilst Independent" if they used to be in a different party
  # TODO Move this to a view helper
  def party_long2
    if entered_reason == "changed_party" || left_reason == "changed_party"
      "whilst #{party_long}"
    else
      party_long
    end
  end

  def senator?
    australian_house == "senate"
  end

  # Returns a number between 0 and 1 or nil
  def attendance_fraction
    votes_attended.to_f / votes_possible if votes_possible > 0
  end

  # Returns a number between 0 and 1 or nil
  def rebellions_fraction
    rebellions.to_f / votes_attended if has_whip? && votes_attended > 0
  end

  # TODO This should be moved to a view helper
  def rebellions_percentage
    if rebellions_fraction
      "%0.1f%" % (rebellions_fraction * 100)
    else
      "n/a"
    end
  end

  # TODO This should be moved to a view helper
  def attendance_percentage
    if attendance_fraction
      "%0.1f%" % (attendance_fraction * 100)
    else
      "n/a"
    end
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

  def self.current
    where(left_house: "9999-12-31")
  end

  # Are they a member of a party that has a whip?
  def has_whip?
    # TODO Should speaker and president be included here?
    party != "Independent" && party != "CWM"
  end
end

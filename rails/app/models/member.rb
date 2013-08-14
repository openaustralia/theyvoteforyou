class Member < ActiveRecord::Base
  self.table_name = "pw_mp"
  has_one :member_info, foreign_key: "mp_id"
  delegate :rebellions, :votes_attended, :votes_possible, to: :member_info
  has_many :offices, foreign_key: "person", primary_key: "person"
  has_many :votes, foreign_key: "mp_id"
  scope :current_on, ->(date) { where("? >= entered_house AND ? < left_house", date, date) }
  scope :in_australian_house, ->(australian_house) { where(house: House.australian_to_uk(australian_house)) }
  # Divisions that have been attended
  has_many :divisions, through: :votes

  # List of parliaments (temporarily here)
  def self.parliaments
    {
      "2010" => {from: Date.new(2010,9,28),  to: Date.new(9999,12,31), name: "2010 (current)"},
      "2007" => {from: Date.new(2008,2,12),  to: Date.new(2010,7,19),  name: "2008-2010"},
      "2004" => {from: Date.new(2004,11,16), to: Date.new(2007,10,17), name: "2004-2007"},
    }
  end

  # All divisions that this member could have attended
  def divisions_possible
    Division.where(house: house).where("division_date >= ? AND division_date < ?", entered_house, left_house)
  end

  # Divisions that this member has voted on where either they were a teller, a rebel (or both) or voting
  # on a free vote
  def interesting_divisions
    # free votes
    divisions.joins(:whips).where(pw_cache_whip: {party: party, whip_guess: "none"})
  end

  def vote_on_division(division)
    vote = votes.where(division_id: division.id).first
    if vote
      vote.vote
    else
      "absent"
    end
  end

  def majority_vote_on_division(division)
    vote = votes.where(division_id: division.id).first
    if vote
      # TODO What happens when the same number of votes on each side? Or can this never happen by design?
      if division.majority_vote == "none"
        vote.vote
      elsif vote.vote == division.majority_vote
        "majority"
      else
        "minority"
      end
    else
      "absent"
    end
  end

  def name
    "#{title} #{first_name} #{last_name}".strip
  end

  def current_offices
    offices_on_date(Date.today)
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
    Member.party_long(party)
  end

  def self.party_long(party)
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
    House.uk_to_australian(house)
  end

  def electorate
    constituency
  end

  # TODO Make this more resilient by using current_on(Date.today)
  def self.current
    where(left_house: "9999-12-31")
  end

  # TODO Move this to a "party" class
  def self.party_has_whip?(party)
    # TODO Should speaker and president be included here?
    party != "Independent" && party != "CWM" && party != "SPK"
  end

  # Are they a member of a party that has a whip?
  def has_whip?
    Member.party_has_whip?(party)
  end
end

class Member < ActiveRecord::Base
  self.table_name = "pw_mp"
  has_one :member_info, foreign_key: "mp_id"
  delegate :rebellions, :votes_attended, :votes_possible, to: :member_info, allow_nil: true
  has_many :offices, foreign_key: "person", primary_key: "person"
  has_many :votes, foreign_key: "mp_id"
  scope :current_on, ->(date) { where("? >= entered_house AND ? < left_house", date, date) }
  scope :in_australian_house, ->(australian_house) { where(house: House.australian_to_uk(australian_house)) unless australian_house == 'all' }
  # Divisions that have been attended
  has_many :divisions, through: :votes

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

  # Include electorate in the name
  def full_name
    if senator?
      name
    else
      "#{name} MP, #{electorate}"
    end
  end

  def full_name_no_electorate
    if senator?
      name
    else
      "#{name} MP"
    end
  end

  def full_name2
    if senator?
      "Senator #{name}"
    else
      "#{name} MP, #{electorate}"
    end
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
    votes_attended.to_f / votes_possible if member_info && votes_possible > 0
  end

  # Returns a number between 0 and 1 or nil
  def rebellions_fraction
    rebellions.to_f / votes_attended if member_info && has_whip? && votes_attended > 0
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
    party != "SPK" &&
    party != "CWM" &&
    party != "DCWM" &&
    party != "PRES" &&
    party != "DPRES" &&
    party != "Independent"
  end

  # Are they a member of a party that has a whip?
  def has_whip?
    Member.party_has_whip?(party)
  end

  def self.find_by_search_query(query_string)
    # FIXME: This convoluted SQL crap was ported directly from the PHP app. Make it nice
    sql_query = "SELECT first_name, last_name, title, constituency, pw_mp.party AS party, pw_mp.house as house,
                        entered_house, left_house,
                        entered_reason, left_reason,
                        pw_mp.mp_id AS mpid,
                        rebellions, votes_attended, votes_possible
                 FROM pw_mp
                 LEFT JOIN pw_cache_mpinfo ON pw_cache_mpinfo.mp_id = pw_mp.mp_id
                 WHERE 1=1"

    score_clause = "("
    score_clause += "(lower(concat(first_name, ' ', last_name)) = '#{query_string}') * 10"
    placeholders = {}
    bitcount = 0
    query_string.split.each do |querybit|
      querybit = querybit.strip
      placeholders["querybit_#{bitcount}".to_sym] = querybit
      placeholders["querybit_wild_#{bitcount}".to_sym] = '%' + querybit + '%'

      if !querybit.blank?
        score_clause += '+ (lower(constituency) =:querybit_' + bitcount.to_s + ') * 10 +
        (soundex(concat(first_name, \' \', last_name)) = soundex(:querybit_' + bitcount.to_s + ')) * 8 +
        (soundex(constituency) = soundex(:querybit_' + bitcount.to_s + ')) * 8 +
        (soundex(last_name) = soundex(:querybit_' + bitcount.to_s + ')) * 6 +
        (lower(constituency) like :querybit_wild_' + bitcount.to_s + ') * 4 +';
        score_clause += '(lower(last_name) like :querybit_wild_' + bitcount.to_s + ') * 4 +
        (soundex(first_name) = soundex(:querybit_' + bitcount.to_s + ')) * 2 +
        (lower(first_name) like :querybit_wild_' + bitcount.to_s + ') +';
        score_clause += '(soundex(constituency) like concat(\'%\',soundex(:querybit_' + bitcount.to_s + '),\'%\'))'
      end
      bitcount += 1
    end

    score_clause += ")"

    sql_query += " AND (#{score_clause} > 0)
                   GROUP BY concat(first_name, ' ', last_name, ' ', constituency)
                   ORDER BY #{score_clause} DESC"

    Member.find_by_sql [sql_query, placeholders]
  end
end

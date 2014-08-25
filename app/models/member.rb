class Member < ActiveRecord::Base
  self.table_name = "pw_mp"
  has_one :member_info, foreign_key: "mp_id"
  delegate :rebellions, :votes_attended, :votes_possible, :tells, to: :member_info, allow_nil: true
  has_many :votes, foreign_key: "mp_id"
  scope :current_on, ->(date) { where("? >= entered_house AND ? < left_house", date, date) }
  scope :in_australian_house, ->(australian_house) { where(house: House.australian_to_uk(australian_house)) unless australian_house == 'all' }
  scope :with_name, ->(name) {
    first_name, last_name = Member.parse_first_last_name(name)
    where(first_name: first_name, last_name: last_name)
  }
  # Divisions that have been attended
  has_many :divisions, through: :votes
  has_many :member_distances, foreign_key: :mp_id1

  # Give it a name like "Kevin Rudd" returns ["Kevin", "Rudd"]
  def self.parse_first_last_name(name)
    name = name.split(" ")
    # Strip titles like "Ms"
    name.slice!(0) if name[0] == 'Ms' || name[0] == 'Mrs' || name[0] == "Mr"
    first_name = name[0]
    last_name = name[1..-1].join(' ')
    [first_name, last_name]
  end

  def person_object
    Person.new(id: person)
  end

  def changed_party?
    entered_reason == "changed_party" || left_reason == "changed_party"
  end

  # All divisions that this member could have attended
  def divisions_possible
    Division.where(house: house).where("division_date >= ? AND division_date < ?", entered_house, left_house)
  end

  # Divisions that this member has voted on where either they were a rebel or voting
  # on a free vote
  def interesting_divisions
    divisions.joins(:whips).where(free_vote.or(rebellious_vote)).group("pw_division.division_id")
  end

  def division_vote(division)
    votes.find_by(division: division)
  end

  def vote_on_division_without_tell(division)
    division_vote(division) ? division_vote(division).vote_without_tell : "absent"
  end

  def rebel_on_division?(division)
    division_vote(division).rebellion? if division_vote(division)
  end

  def majority_vote_on_division_without_tell(division)
    vote = votes.where(division_id: division.id).first
    if vote
      # TODO What happens when the same number of votes on each side? Or can this never happen by design?
      if division.majority_vote == "none"
        vote.vote_without_tell
      elsif vote.vote_without_tell == division.majority_vote
        "majority"
      else
        "minority"
      end
    else
      "absent"
    end
  end

  def name
    "#{title} #{name_without_title}".strip
  end

  def original_name
    "#{title} #{original_name_without_title}".strip
  end

  def name_without_title
    "#{first_name} #{last_name}".strip
  end

  def original_name_without_title
    "#{first_name} #{original_last_name}".strip
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

  def in_parliament_on_date(date)
    date >= entered_house && date < left_house
  end

  def currently_in_parliament?
    in_parliament_on_date(Date.today)
  end

  # Last name as it's stored in the database including horrible html entities
  # which for some reason are in there
  def original_last_name
    read_attribute(:last_name)
  end

  def last_name
    # For some reason some characters are stored in the database using html entities
    # rather than using unicode.
    HTMLEntities.new.decode(original_last_name)
  end

  def original_constituency
    read_attribute(:constituency)
  end

  def constituency
    # For some reason some characters are stored in the database using html entities
    # rather than using unicode.
    HTMLEntities.new.decode(original_constituency)
  end

  # Long version of party name
  def party_long
    Party.long_name(party)
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

  def url_name
    CGI::escape(original_name_without_title.gsub(" ", "_"))
  end

  def url_name_with_title
    CGI::escape(original_name.gsub(" ", "_"))
  end

  def url_electorate
    CGI::escape(original_constituency.gsub(" ", "_"))
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

  # Are they a member of a party that has a whip?
  def has_whip?
    !Party.whipless?(party)
  end

  def possible_friends
    member_distances.where.not(mp_id2: id, distance_a: -1)
  end

  # Friends who have voted exactly the same
  def best_friends
    possible_friends.where(distance_a: 0)
  end

  def self.find_by_search_query(query_string)
    # FIXME: This convoluted SQL crap was ported directly from the PHP app. Make it nice
    sql_query = "SELECT person, first_name, last_name, title, constituency, pw_mp.party AS party, pw_mp.house as house,
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

  private

  def free_vote
    whip = Whip.arel_table
    whip[:party].eq(party).and(whip[:whip_guess].eq("none"))
  end

  def rebellious_vote
    whip = Whip.arel_table
    vote = Vote.arel_table
    aye = (vote[:vote].eq("aye")).or(vote[:vote].eq("tellaye"))
    no = (vote[:vote].eq("no")).or(vote[:vote].eq("tellno"))
    rebel_aye = aye.and(whip[:whip_guess].eq("no"))
    rebel_no = no.and(whip[:whip_guess].eq("aye"))
    whip[:party].eq(party).and(rebel_aye.or(rebel_no))
  end
end

class Member < ActiveRecord::Base
  has_one :member_info, dependent: :destroy
  delegate :rebellions, :votes_attended, :votes_possible, :tells, to: :member_info, allow_nil: true
  has_many :votes, dependent: :destroy
  scope :current_on, ->(date) { where("? >= entered_house AND ? < left_house", date, date) }
  scope :in_australian_house, ->(australian_house) { where(house: House.australian_to_uk(australian_house)) }
  scope :with_name, ->(name) {
    first_name, last_name = Member.parse_first_last_name(name)
    where(first_name: first_name, last_name: last_name)
  }
  # Divisions that have been attended
  has_many :divisions, through: :votes
  has_many :member_distances, foreign_key: :member1_id

  delegate :small_image_url, :large_image_url, to: :person

  # Give it a name like "Kevin Rudd" returns ["Kevin", "Rudd"]
  def self.parse_first_last_name(name)
    name = name.split(" ")
    # Strip titles like "Ms"
    name.slice!(0) if name[0] == 'Ms' || name[0] == 'Mrs' || name[0] == "Mr"
    first_name = name[0]
    last_name = name[1..-1].join(' ')
    [first_name, last_name]
  end

  def person
    Person.new(id: person_id)
  end

  def changed_party?
    entered_reason == "changed_party" || left_reason == "changed_party"
  end

  # All divisions that this member could have attended
  def divisions_possible
    Division.where(house: house).where("date >= ? AND date < ?", entered_house, left_house)
  end

  # Divisions that this member has voted on where either they were a rebel or voting
  # on a free vote
  def interesting_divisions
    divisions.joins(:whips).where(free_vote.or(rebellious_vote)).group("divisions.id")
  end

  def division_vote(division)
    votes.find_by(division: division)
  end

  def vote_on_division_without_tell(division)
    division_vote(division) ? division_vote(division).vote : "absent"
  end

  def rebel_on_division?(division)
    division_vote(division).rebellion? if division_vote(division)
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
      "Senator #{name}"
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

  def role
    if senator?
      "Senator  for #{electorate}"
    else
      "MP for #{electorate}"
    end
  end

  def in_parliament_on_date(date)
    date >= entered_house && date < left_house
  end

  def currently_in_parliament?
    in_parliament_on_date(Date.today)
  end

  def since
    entered_house.strftime('%B %Y')
  end

  def until
    left_house > Date.today ? 'today' : left_house.strftime('%B %Y')
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
  def party_name
    party_object.long_name
  end

  # Are they a member of a party that has a whip?
  def has_whip?
    party_object.has_whip?
  end

  def party_object
    Party.new(name: party)
  end

  def senator?
    australian_house == "senate"
  end

  def url_name
    original_name_without_title.gsub(" ", "_")
  end

  def url_electorate
    original_constituency.gsub(" ", "_")
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

  def possible_friends
    member_distances.where.not(member2_id: id, distance_a: -1)
  end

  # Friends who have voted exactly the same
  def best_friends
    possible_friends.where(distance_a: 0)
  end

  def self.find_by_search_query(query_string)
    # FIXME: This convoluted SQL crap was ported directly from the PHP app. Make it nice
    sql_query = "SELECT person_id, first_name, last_name, title, constituency, members.party AS party, members.house as house,
                        entered_house, left_house,
                        entered_reason, left_reason,
                        members.id AS mpid,
                        rebellions, votes_attended, votes_possible
                 FROM members
                 LEFT JOIN member_infos ON member_infos.member_id = members.id
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
                   ORDER BY #{score_clause} DESC, last_name"

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
    rebel_aye = vote[:vote].eq("aye").and(whip[:whip_guess].eq("no"))
    rebel_no = vote[:vote].eq("no").and(whip[:whip_guess].eq("aye"))
    whip[:party].eq(party).and(rebel_aye.or(rebel_no))
  end
end

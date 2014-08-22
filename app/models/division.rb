class Division < ActiveRecord::Base
  self.table_name = "pw_division"

  has_one :division_info
  has_many :whips
  has_many :votes

  delegate :turnout, :aye_majority, to: :division_info
  alias_attribute :date, :division_date
  alias_attribute :name, :division_name
  alias_attribute :number, :division_number

  scope :in_house, ->(house) { where(house: house) }
  scope :in_australian_house, ->(australian_house) { in_house(House.australian_to_uk(australian_house)) }
  # TODO This doesn't exactly match the wording in the interface. Fix this.
  scope :with_rebellions, -> { joins(:division_info).where("rebellions > 10") }
  scope :in_parliament, ->(parliament) { where("division_date >= ? AND division_date < ?", parliament[:from], parliament[:to]) }

  # TODO Convert this to an association when we refer to division by id. Need to make sure that
  # division loading code doesn't change id's
  def policy_divisions
    PolicyDivision.where(division_date: date,
                         division_number: number,
                         house: house)
  end

  # TODO Convert to an association. See above
  def policies
    policy_divisions.collect { |pd| pd.policy } if policy_divisions
  end

  def wiki_motions
    WikiMotion.order(edit_date: :desc).where(division_date: date, division_number: number, house: house)
  end

  def wiki_motion
    WikiMotion.order(edit_date: :desc).find_by(division_date: date, division_number: number, house: house)
  end

  def self.most_recent_date
    order(division_date: :desc).first.division_date
  end

  def rebellious?
    no_rebellions > 10
  end

  def whip_guess_for(party)
    whips.where(party: party).first.whip_guess
  end

  def role_for(member)
    (v = votes.find_by(mp_id: member.id)) ? v.role : "absent"
  end

  def vote_for(member)
    member.vote_on_division_without_tell(self)
  end

  def majority_vote_for(member)
    member.majority_vote_on_division_without_tell(self)
  end

  # Equal number of votes for the ayes and noes
  def tied?
    aye_majority == 0
  end

  # The vote of the majority (either aye or no)
  def majority_vote
    if aye_majority == 0
      "none"
    elsif aye_majority > 0
      "aye"
    else
      "no"
    end
  end

  def no_rebellions
    division_info.rebellions
  end

  # Using whips cache to calculate this. Is this the best way?
  # No. should use values from division_info
  def aye_votes
    whips.to_a.sum(&:aye_votes)
  end

  def aye_tells
    whips.to_a.sum(&:aye_tells)
  end

  def no_votes
    whips.to_a.sum(&:no_votes)
  end

  def no_tells
    whips.to_a.sum(&:no_tells)
  end

  def total_votes
    whips.to_a.sum(&:total_votes)
  end

  def aye_votes_including_tells
    aye_votes + aye_tells
  end

  def no_votes_including_tells
    no_votes + no_tells
  end

  # Only include in the total possible votes the parties that actually voted.
  # Only doing this to match php implementation which in my opinion is not correct
  # Should really just be whips.sum(&:possible_votes)
  def possible_votes
    whips.find_all{|w| w.total_votes > 0}.sum(&:possible_votes)
  end

  # Returns nil if otherwise we would get divide by zero
  def attendance_fraction
    if possible_votes > 0
      total_votes.to_f / possible_votes
    end
  end

  def division_name
    wiki_motion ? wiki_motion.text_body[/--- DIVISION TITLE ---(.*)--- MOTION EFFECT/m, 1].strip.gsub('-', '—') : original_name
  end

  def original_name
    # For some reason some characters are stored in the database using html entities
    # rather than using unicode.
    HTMLEntities.new.decode(read_attribute(:division_name).gsub('-', '—'))
  end

  def motion
    text = wiki_motion ? wiki_motion.text_body[/--- MOTION EFFECT ---(.*)--- COMMENT/m, 1].strip : read_attribute(:motion)
    # For some reason some characters are stored in the database using html entities
    # rather than using unicode.
    text = HTMLEntities.new.decode(text)
    # FIXME This is just to match the PHP app. Why the hell is it the opposite to the name??
    text.gsub('—', '-')
  end

  def original_motion
    read_attribute(:motion)
  end

  def motion_edited?
    !wiki_motion.nil?
  end

  def oa_debate_url
    case australian_house
    when "representatives"
      "http://www.openaustralia.org/debates/?id=#{oa_debate_id}"
    when "senate"
      "http://www.openaustralia.org/senate/?id=#{oa_debate_id}"
    else
      raise "unexexpected value"
    end
  end

  def oa_debate_id
    # This probably won't generalise to the senate
    debate_gid.split("/")[2]
  end

  # This is a bit of a guess
  def majority
    aye_majority.abs
  end

  def clock_time
    text = read_attribute(:clock_time)
    Time.parse(text) unless text.blank?
  end

  def australian_house
    House.uk_to_australian(house)
  end

  def australian_house=(h)
    self.house = House.australian_to_uk(h)
  end

  def australian_house_name
    australian_house.capitalize
  end

  def noes_in_majority?
    aye_majority < 0
  end

  def majority_type
    noes_in_majority? ? "no" : "aye"
  end

  def minority_type
    noes_in_majority? ? "aye" : "no"
  end

  def majority_votes
    noes_in_majority? ? no_votes : aye_votes
  end

  def majority_votes_including_tells
    noes_in_majority? ? no_votes_including_tells : aye_votes_including_tells
  end

  def minority_votes
    noes_in_majority? ? aye_votes : no_votes
  end

  def minority_votes_including_tells
    noes_in_majority? ? aye_votes_including_tells : no_votes_including_tells
  end

  def policy_division(policy)
    policy_divisions.find_by!(dream_id: policy.id)
  end

  def policy_vote_strong?(policy)
    policy_division(policy).strong_vote?
  end

  def policy_vote(policy)
    policy_division(policy).vote
  end

  # Extracts specially formatted voting actions that the user enters as comments
  # in the motion text. They're formatted like '@MP voted aye to say this vote was great'
  # where the text will say "Tony Abbott voted to say this vote was great" if he votes aye
  def action_text
    Hash[motion.scan(/^@\s*MP voted (aye|no) (.*)/)]
  end

  def create_wiki_motion!(title, description, user)
    WikiMotion.create!(division_date: date,
                       division_number: number,
                       house: house,
                       title: title,
                       description: description,
                       user: user,
                       edit_date: Time.now)
  end

  def self.find_by_search_query(query)
    update_divisions_wiki_id!

    # FIXME: Remove nasty SQL below that was ported from PHP direct
    joins('LEFT JOIN pw_cache_divwiki ON pw_cache_divwiki.division_date = pw_division.division_date
           AND pw_cache_divwiki.division_number = pw_division.division_number AND pw_cache_divwiki.house = pw_division.house
           LEFT JOIN wiki_motions ON wiki_motions.wiki_id = pw_cache_divwiki.wiki_id')
          .where('LOWER(convert(division_name using utf8)) LIKE :query
                  OR LOWER(convert(motion using utf8)) LIKE :query
                  OR LOWER(convert(text_body using utf8)) LIKE :query', query: "%#{query}%")
  end

  # FIXME: Cargo cult SQL update from PHP's update_divisions_wiki_id() function
  def self.update_divisions_wiki_id!
    ActiveRecord::Base.connection.execute("INSERT INTO pw_cache_divwiki
                                           (division_date, division_number, house, wiki_id)
                                           SELECT pw_division.division_date AS division_date,
                                                  pw_division.division_number AS division_number,
                                                  pw_division.house AS house,
                                                  IFNULL(MAX(wiki_motions.wiki_id), -1) AS value
                                           FROM pw_division
                                           LEFT JOIN pw_cache_divwiki ON pw_division.division_date = pw_cache_divwiki.division_date AND
                                               pw_division.division_number = pw_cache_divwiki.division_number
                                           LEFT JOIN wiki_motions ON wiki_motions.division_date = pw_division.division_date
                                               AND wiki_motions.division_number = pw_division.division_number
                                               AND wiki_motions.house = pw_division.house
                                           WHERE pw_cache_divwiki.wiki_id IS NULL
                                           GROUP BY pw_division.division_id")
  end
end

class Division < ActiveRecord::Base
  has_one :division_info
  has_many :whips
  has_many :votes
  has_many :policy_divisions
  has_many :policies, through: :policy_divisions
  has_many :wiki_motions, -> {order(edit_date: :desc)}

  delegate :turnout, :aye_majority, to: :division_info

  scope :in_house, ->(house) { where(house: house) }
  scope :in_australian_house, ->(australian_house) { in_house(House.australian_to_uk(australian_house)) }
  # TODO This doesn't exactly match the wording in the interface. Fix this.
  scope :with_rebellions, -> { joins(:division_info).where("rebellions > 10") }
  scope :in_parliament, ->(parliament) { where("date >= ? AND date < ?", parliament[:from], parliament[:to]) }

  def wiki_motion
    wiki_motions.first
  end

  def self.most_recent_date
    order(date: :desc).first.date
  end

  def rebellious?
    no_rebellions > 10
  end

  def whip_guess_for(party)
    whips.where(party: party).first.whip_guess
  end

  def role_for(member)
    (v = votes.find_by(member_id: member.id)) ? v.role : "absent"
  end

  def vote_for(member)
    member.vote_on_division_without_tell(self)
  end

  # Equal number of votes for the ayes and noes
  def tied?
    aye_majority == 0
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

  def name
    wiki_motion ? wiki_motion.text_body[/--- DIVISION TITLE ---(.*)--- MOTION EFFECT/m, 1].strip.gsub('-', '—') : original_name
  end

  def original_name
    # For some reason some characters are stored in the database using html entities
    # rather than using unicode.
    HTMLEntities.new.decode(read_attribute(:name).gsub('-', '—'))
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

  def policy_division(policy)
    policy_divisions.find_by!(policy_id: policy.id)
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
    wiki_motions.create!(title: title,
      description: description,
      user: user,
      # TODO Use default rails created_at instead
      edit_date: Time.now)
  end

  def self.find_by_search_query(query)
    # FIXME: Remove nasty SQL below that was ported from PHP direct
    joins('LEFT JOIN wiki_motions ON wiki_motions.id = (SELECT IFNULL(MAX(wiki_motions.id), -1) FROM wiki_motions  WHERE wiki_motions.division_id = divisions.id)')
          .where('LOWER(convert(name using utf8)) LIKE :query
                  OR LOWER(convert(motion using utf8)) LIKE :query
                  OR LOWER(convert(text_body using utf8)) LIKE :query', query: "%#{query}%")
  end
end

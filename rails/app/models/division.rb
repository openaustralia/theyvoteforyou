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

  def policy_divisions
    PolicyDivision.where(division_date: date,
                         division_number: number,
                         house: house)
  end

  def division_wiki
    DivisionWiki.where(division_date: date,
                       division_number: number,
                       house: house).first
  end

  def policies
    policy_divisions.collect { |pd| pd.policy } if policy_divisions
  end

  def wiki_motion
    if division_wiki && division_wiki.wiki_id != -1
      WikiMotion.find_by_wiki_id(division_wiki.wiki_id)
    end
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
    v = votes.where(mp_id: member.id).first
    if v
      v.role
    else
      "absent"
    end
  end

  def vote_for(member)
    member.vote_on_division(self)
  end

  def majority_vote_for(member)
    member.majority_vote_on_division(self)
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

  # TODO Fix this hacky nonsense by doing this query in the db
  def rebellions_order_party
    votes.joins(:member).order("pw_mp.party", "pw_mp.last_name", "pw_mp.first_name").find_all{|v| v.rebellion?}
  end

  def rebellions_order_name
    votes.joins(:member).order("pw_mp.last_name", "pw_mp.first_name").find_all{|v| v.rebellion?}
  end

  def rebellions_order_constituency
    votes.joins(:member).order("pw_mp.constituency", "pw_mp.last_name", "pw_mp.first_name").find_all{|v| v.rebellion?}
  end

  def rebellions_order_vote
    votes.joins(:member).order(:vote, "pw_mp.last_name", "pw_mp.first_name").find_all{|v| v.rebellion?}
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

  def attendance_fraction
    total_votes.to_f / possible_votes
  end

  def division_name
    wiki_text = wiki_motion.text_body[/--- DIVISION TITLE ---(.*)--- MOTION EFFECT/m, 1].strip if wiki_motion
    # For some reason some characters are stored in the database using html entities
    # rather than using unicode.
    HTMLEntities.new.decode(wiki_text || read_attribute(:division_name)).gsub('-', '—')
  end

  def motion
    wiki_motion ? wiki_motion.text_body[/--- MOTION EFFECT ---(.*)--- COMMENT/m, 1].strip : read_attribute(:motion)
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
    Time.parse(text) if text && text != ""
  end

  def australian_house
    House.uk_to_australian(house)
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

  def policy_vote(policy)
    policy_division = policy_divisions.where(dream_id: policy.id)
    raise if policy_division.size > 1
    policy_division.first.vote
  end
end

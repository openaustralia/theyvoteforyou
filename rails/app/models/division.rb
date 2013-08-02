class Division < ActiveRecord::Base
  self.table_name = "pw_division"

  has_one :division_info
  has_many :whips

  delegate :rebellions, :turnout, :aye_majority, to: :division_info
  alias_attribute :date, :division_date
  alias_attribute :name, :division_name
  alias_attribute :number, :division_number

  scope :in_house, ->(house) { where(house: house) }
  scope :in_australian_house, ->(australian_house) { in_house(Division.australian_to_uk_house(australian_house)) }
  # TODO This doesn't exactly match the wording in the interface. Fix this.
  scope :with_rebellions, -> { where("rebellions > 10") }
  scope :in_parliament, ->(parliament) { where("division_date >= ? AND division_date < ?", parliament[:from], parliament[:to]) }

  # Using whips cache to calculate this. Is this the best way?
  # No. should use values from division_info
  def aye_votes
    whips.sum(&:aye_votes)
  end

  def aye_tells
    whips.sum(&:aye_tells)
  end

  def no_votes
    whips.sum(&:no_votes)
  end

  def no_tells
    whips.sum(&:no_tells)
  end

  def both_votes
    whips.sum(&:both_votes)
  end

  def total_votes
    whips.sum(&:total_votes)
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

  # TODO move this to a helper
  def attendance_percentage
    "%0.1f%" % (attendance_fraction * 100)
  end

  def division_name
    # For some reason some characters are stored in the database using html entities
    # rather than using unicode.
    HTMLEntities.new.decode(read_attribute(:division_name))
  end

  def oa_debate_url
    "http://www.openaustralia.org/debates/?id=#{oa_debate_id}"
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
    Division.uk_to_australian_house(house)
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

  def self.uk_to_australian_house(house)
    case house
    when "commons"
      "representatives"
    when "lords"
      "senate"
    else
      raise "Unexpected value"
    end
  end

  def self.australian_to_uk_house(australian_house)
    case australian_house
    when "representatives"
      "commons"
    when "senate"
      "lords"
    else
      raise "unexpected value"
    end
  end
end

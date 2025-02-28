# frozen_string_literal: true

class Member < ApplicationRecord
  # TODO: Remove source_gid from schema as it's not being used (but still loaded by the loaders)
  searchkick index_name: "tvfy_members_#{Settings.stage}"
  has_one :member_info, dependent: :destroy
  delegate :rebellions, :votes_attended, :votes_possible, :tells, to: :member_info, allow_nil: true
  has_many :votes, dependent: :destroy
  scope :current_on, ->(date) { where("? >= entered_house AND ? < left_house", date, date) }
  scope :in_house, ->(house) { where(house: house) }
  scope :with_name, lambda { |name|
    first_name, last_name = Member.parse_first_last_name(name)
    where(first_name: first_name, last_name: last_name)
  }
  # TODO: Make this more resilient by using current_on(Date.today)
  scope :current, -> { where(left_house: "9999-12-31") }

  # TODO: "title" is unused in application. Remove it from the schema (after removing it from the data_loader)

  # Divisions that have been attended
  has_many :divisions, through: :votes
  belongs_to :person, touch: true

  delegate :show_small_image?, :small_image_url, :small_image_width, :small_image_height,
           :small_image_size,
           :show_large_image?, :large_image_url, :large_image_width, :large_image_height,
           :large_image_size,
           :show_extra_large_image?, :extra_large_image_url, :extra_large_image_width, :extra_large_image_height,
           :extra_large_image_size,
           to: :person

  def date_range
    entered_house...left_house
  end

  # Tell searchkick that we want to index only certain things
  def search_data
    {
      # Indexing full name so we can search on full name
      name: name,
      constituency: constituency
    }
  end

  def self.random(collection)
    # While testing make this deterministic
    if Rails.env.test?
      collection.first
    else
      collection.offset(rand(collection.count)).first
    end
  end

  # Randomly pick a postcode from a small selection that covers each State and Territory
  # in Australia where the postcode only relates to one electorate.
  def self.random_postcode
    postcodes = %w[0836 2300 2902 3219 4570 6280 7320]
    if Rails.env.test?
      postcodes.first
    else
      postcodes[rand(7)]
    end
  end

  # Return a random member of parliament who is currently there
  def self.random_current
    random(Member.current)
  end

  # Give it a name like "Kevin Rudd" returns ["Kevin", "Rudd"]
  def self.parse_first_last_name(name)
    name = name.split
    # Strip titles like "Ms"
    name.slice!(0) if name[0] == "Ms" || name[0] == "Mrs" || name[0] == "Mr"
    first_name = name[0]
    last_name = name[1..].join(" ")
    [first_name, last_name]
  end

  def self.find_with_url_params(house:, mpc:, mpn:)
    electorate = mpc.gsub("_", " ")
    name = mpn.gsub("_", " ")

    with_name(name).in_house(house).where(constituency: electorate).order(entered_house: :desc).first
  end

  def url_params
    {
      house: house,
      mpc: url_electorate.downcase,
      mpn: url_name.downcase
    }
  end

  def divisions_they_could_have_attended
    Division.possible_for_member(self).order(date: :desc, clock_time: :desc, name: :asc)
  end

  def divisions_they_could_have_attended_between(date_start, date_end)
    divisions_they_could_have_attended.in_date_range(date_start, date_end)
  end

  def rebellious_divisions
    divisions.joins(:whips).where(rebellious_vote)
  end

  def free_divisions
    divisions.joins(:whips).where(free_vote)
  end

  def division_vote(division)
    votes.find_by(division: division)
  end

  def vote_on_division_without_tell(division)
    division_vote(division) ? division_vote(division).vote : "absent"
  end

  def name
    "#{first_name} #{last_name}".strip
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
      "Senator for #{electorate}"
    else
      "Representative for #{electorate}"
    end
  end

  def in_parliament_on_date(date)
    date >= entered_house && date < left_house
  end

  def currently_in_parliament?
    in_parliament_on_date(Time.zone.today)
  end

  def could_have_voted_in_division?(division)
    in_parliament_on_date(division.date) && house == division.house
  end

  # Long version of party name
  def party_name
    party_object.long_name
  end

  # Are they a member of a party that has a whip?
  delegate :subject_to_whip?, to: :party_object

  def party_object
    @party_object ||= Party.new(name: party)
  end

  def senator?
    house == "senate"
  end

  def url_name
    name.gsub(" ", "_")
  end

  def url_electorate
    constituency.gsub(" ", "_")
  end

  def electorate
    constituency
  end

  # Members who were in parliament (in the same house) at the same time
  # Note that this also includes themselves
  def overlapping_members
    Member.where(house: house).where("left_house >= ?", entered_house).where("entered_house <= ?", left_house)
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

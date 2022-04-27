# frozen_string_literal: true

class Division < ApplicationRecord
  # debate_gid is currently used to generate links to debates on openaustralia.org.au. It would be better
  # to use the debate_url field for that. Currently that's completely ignored as it's overridden
  # below.
  # TODO: Do a data migration so that the debate_url field is the openaustralia.org.au url and debate_gid can be removed

  searchkick index_name: "tvfy_divisions_#{Settings.stage}"
  has_one :division_info, dependent: :destroy
  has_many :whips, dependent: :destroy
  has_many :votes, dependent: :destroy
  has_many :policy_divisions, dependent: :destroy
  has_many :policies, through: :policy_divisions
  has_many :wiki_motions, -> { order(created_at: :desc) }, inverse_of: :division, dependent: :destroy
  has_and_belongs_to_many :bills

  delegate :turnout, :aye_majority, :rebellions, :majority, :majority_fraction, to: :division_info

  scope :in_date_range, ->(date_start, date_end) { where("date >= ? AND date < ?", date_start, date_end) }
  scope :in_house, ->(house) { where(house: house) }
  scope :in_parliament, ->(parliament) { where("date >= ? AND date < ?", parliament[:from], parliament[:to]) }
  scope :possible_for_member, ->(member) { where(house: member.house).where("date >= ? AND date < ?", member.entered_house, member.left_house) }
  scope :edited, -> { joins(:wiki_motions).distinct }
  scope :unedited, -> { joins("LEFT JOIN wiki_motions ON wiki_motions.division_id = divisions.id").where(wiki_motions: { division_id: nil }) }

  def self.date_earliest_division
    Division.order(:date).first.date
  end

  def url_params
    {
      date: date,
      number: number,
      house: house
    }
  end

  def members_who_could_have_voted
    Member.current_on(date).where(house: house)
  end

  def wiki_motion
    wiki_motions.first
  end

  # Other divisions related to this one because they consider the same bills
  def related_divisions
    bills.map(&:divisions).flatten.uniq.reject { |d| d == self }
  end

  def whip_for_party(party)
    whips.find_by(party: party)
  end

  def self.most_recent_date
    order(date: :desc).first.date
  end

  def vote_for(member)
    member.vote_on_division_without_tell(self)
  end

  def passed?
    tied? ? false : aye_majority >= 1
  end

  # Equal number of votes for the ayes and noes
  def tied?
    aye_majority.zero?
  end

  # Did everyone vote the same way?
  # TODO: Move this to division_info and delegate
  def unanimous?
    turnout.positive? && majority == turnout
  end

  # Using whips cache to calculate this. Is this the best way?
  # TODO No. should use values from division_info
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
    division_info.turnout
  end

  def aye_votes_including_tells
    aye_votes + aye_tells
  end

  def no_votes_including_tells
    no_votes + no_tells
  end

  def possible_votes
    division_info.possible_turnout
  end

  add_method_tracer :possible_votes, "Custom/Division/possible_votes"

  # Returns nil if otherwise we would get divide by zero
  def attendance_fraction
    total_votes.to_f / possible_votes if possible_votes.positive?
  end

  def edited?
    !wiki_motion.nil?
  end

  def name
    wiki_motion ? wiki_motion.title.strip : original_name
  end

  add_method_tracer :name, "Custom/Division/name"

  def original_name
    # For some reason some characters are stored in the database using html entities
    # rather than using unicode.
    HTMLEntities.new.decode(self[:name])
  end

  add_method_tracer :original_name, "Custom/Division/original_name"

  def motion
    text = if edited?
             wiki_motion.description.strip
           else
             ReverseMarkdown.convert(self[:motion])
           end
    # For some reason some characters are stored in the database using html entities
    # rather than using unicode.
    HTMLEntities.new.decode(text)
  end

  def original_motion
    self[:motion]
  end

  def history
    (wiki_motions + PaperTrail::Version.where(division_id: id)).sort_by(&:created_at).reverse
  end

  def last_edit
    history.first
  end

  def last_edited_at
    last_edit.created_at
  end

  def last_edited_by
    last_edit.is_a?(PaperTrail::Version) ? User.find(last_edit.whodunnit) : last_edit.user
  end

  def debate_url
    case house
    when "representatives"
      "https://www.openaustralia.org.au/debates/?id=#{oa_debate_id}"
    when "senate"
      "https://www.openaustralia.org.au/senate/?id=#{oa_debate_id}"
    else
      super
    end
  end

  def oa_debate_id
    # This probably won't generalise to the senate
    debate_gid.split("/")[2]
  end

  # TODO: We should really be doing any tidying up of the clock time in the loader and
  # we should make the field an actual time rather than a free text field
  def clock_time
    text = self[:clock_time]
    Time.zone.parse(text).strftime("%l:%M %p") if text.present?
  end

  def house_name
    house.capitalize
  end

  def full_house_name
    house == "representatives" ? "House of Representatives" : house_name
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

  def build_wiki_motion(title, description, user)
    wiki_motions.new(title: title,
                     description: description,
                     user: user)
  end

  # rubocop:disable Rails/OutputSafety
  def formatted_motion_text
    text = Division.render_markdown(motion)
    # This is a small hack to make links to an old site point to the new site
    text.gsub!(%r{<a href="http://publicwhip-(test|rails).openaustraliafoundation.org.au},
               "<a href=\"https://theyvoteforyou.org.au")

    # Since this is directly coming from the markdown renderer it
    # should be absent of any bad html so we can mark it as safe
    # TODO: We should be probably do an extra level of sanitisation on this so
    # we can avoid calling html_safe entirely
    text.html_safe
  end
  # rubocop:enable Rails/OutputSafety

  def self.render_markdown(text)
    # TODO: Don't reinstantiate the markdown renderer on each request
    md = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    md.render(text)
  end

  def self.next_month(month)
    (Date.parse("#{month}-01") + 1.month).to_s
  end
end

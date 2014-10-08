class Division < ActiveRecord::Base
  has_one :division_info
  has_many :whips
  has_many :votes
  has_many :policy_divisions
  has_many :policies, through: :policy_divisions
  has_many :wiki_motions, -> {order(edit_date: :desc)}
  has_one :wiki_motion, -> {order(edit_date: :desc)}
  has_and_belongs_to_many :bills
  
  delegate :turnout, :aye_majority, :rebellions, :majority, :majority_fraction, to: :division_info

  scope :in_house, ->(house) { where(house: house) }
  scope :in_australian_house, ->(australian_house) { in_house(House.australian_to_uk(australian_house)) }
  scope :in_parliament, ->(parliament) { where("date >= ? AND date < ?", parliament[:from], parliament[:to]) }
  scope :edited, -> { joins(:wiki_motion) }
  scope :unedited, -> { joins("LEFT JOIN wiki_motions ON wiki_motions.division_id = divisions.id").where(wiki_motions: {division_id: nil}) }

  # Other divisions related to this one because they consider the same bills
  def related_divisions
    bills.map{|b| b.divisions}.flatten.uniq.select{|d| d != self}
  end

  def whip_for_party(party)
    whips.find_by(party: party)
  end

  def no_rebellions_in_party(party)
    whip_for_party(party).no_rebels
  end

  def no_loyal_in_party(party)
    whip_for_party(party).no_loyal
  end

  def attendance_fraction_in_party(party)
    whip_for_party(party).attendance_fraction
  end

  def self.most_recent_date
    order(date: :desc).first.date
  end

  def rebellious?
    rebellions > 10
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

  def passed?
    tied? ? false : aye_majority >= 1
  end

  # Equal number of votes for the ayes and noes
  def tied?
    aye_majority == 0
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

  add_method_tracer :possible_votes, 'Custom/Division/possible_votes'

  # Returns nil if otherwise we would get divide by zero
  def attendance_fraction
    if possible_votes > 0
      total_votes.to_f / possible_votes
    end
  end

  def edited?
    !wiki_motion.nil?
  end

  def name
    wiki_motion ? wiki_motion.title.strip : original_name
  end

  add_method_tracer :name, 'Custom/Division/name'

  def original_name
    # For some reason some characters are stored in the database using html entities
    # rather than using unicode.
    HTMLEntities.new.decode(read_attribute(:name))
  end

  add_method_tracer :original_name, 'Custom/Division/original_name'

  def motion
    if edited?
      text = wiki_motion.description.strip
    elsif markdown?
      text = ReverseMarkdown.convert(read_attribute(:motion))
    else
      text = read_attribute(:motion)
    end
    # For some reason some characters are stored in the database using html entities
    # rather than using unicode.
    HTMLEntities.new.decode(text)
  end

  def original_motion
    read_attribute(:motion)
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

  # TODO We should really be doing any tidying up of the clock time in the loader and
  # we should make the field an actual time rather than a free text field
  def clock_time
    text = read_attribute(:clock_time)
    if text.present?
      Time.parse(text).strftime("%l:%M %p")
    end
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
    build_wiki_motion(title, description, user).save!
  end

  def build_wiki_motion(title, description, user)
    wiki_motions.new(title: title,
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

  def formatted_motion_text
    text = self.motion

    if markdown?
      text = Division.render_markdown(text)

    # Don't wiki-parse large amounts of text as it can blow out CPU/memory.
    # It's probably not edited and formatted in wiki markup anyway. Maximum
    # field size is 65,535 characters. 15,000 characters is more than 12 pages,
    # i.e. more than enough.
    elsif text.size > 15000
      text = wikimarkup_parse_basic(text)
    else
      text = wikimarkup_parse(text)
    end

    text.html_safe
  end

  def self.render_markdown(text)
    # TODO Don't reinstantiate the markdown renderer on each request
    md = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    md.render(text)
  end

  def self.footnotes(text)
    result = {}
    text.lines.each do |line|
      # TODO I guess it should only match to the beginning of the line
      if line =~ /\* \[(\d+)\] (.*)/
        result[$1] = $2
      end
    end
    result
  end

  def self.remove_footnotes(text)
    text = text.lines.select{|l| !(l =~ /\* \[(\d+)\] (.*)/)}.join
    # Remove last line containing ''References'' if it's there
    if text.strip.lines.last == "''References''"
      text.strip.lines[0..-2].join
    else
      text
    end
  end

  def self.inline_footnotes(text)
    footnotes = footnotes(text)
    remove_footnotes(text).gsub(/\[(\d+)\]/) { "(#{footnotes[$1]})"}
  end

  private

  # Format according to Public Whip's unique-enough-to-be-annoying markup language.
  # It's *similar* to MediaWiki but not quite. It would be so nice to switch to Markdown.
  def wikimarkup_parse(text)
    text.gsub!(/<p class="italic">(.*)<\/p>/) { "<p><i>#{$~[1]}</i></p>" }
    # Remove any preceeding spaces so wikiparser doesn't format with monospaced font
    text.gsub! /^ */, ''
    # Remove comment lines (those starting with '@')
    text = text.lines.reject { |l| l =~ /(^@.*)/ }.join
    # Italics
    text.gsub!(/''(.*?)''/) { "<em>#{$~[1]}</em>" }
    # Parse as MediaWiki
    text = Marker.parse(text).to_html(nofootnotes: true)
    # Strip unwanted tags and attributes
    text = sanitize_motion(text)

    # BUG: Force object back to String from ActiveSupport::SafeBuffer so the below regexs work properly
    text = String.new(text)

    # Footnote links. The MediaWiki parser would mess these up so we do them after parsing
    text.gsub!(/(?<![<li>\s])(\[(\d+)\])/) { %(<sup class="sup-#{$~[2]}"><a class="sup" href='#footnote-#{$~[2]}' onclick="ClickSup(#{$~[2]}); return false;">#{$~[1]}</a></sup>) }
    # Footnotes
    text.gsub!(/<li>\[(\d+)\]/) { %(<li class="footnote" id="footnote-#{$~[1]}">[#{$~[1]}]) }

    # This is a small hack to make links to an old site point to the new site
    text.gsub!("<a href=\"http://publicwhip-test.openaustraliafoundation.org.au",
      "<a href=\"http://publicwhip-rails.openaustraliafoundation.org.au")
    text
  end

  # Use this in situations where the text is huge and all we want is it to output something
  # similar to what the php is outputting. So, we do a stripped down version of wikimarkup_parse
  # without the stuff that blows up when the text is huge
  def wikimarkup_parse_basic(text)
    text.gsub!(/<p class="italic">(.*)<\/p>/) { "<p><i>#{$~[1]}</i></p>" }
    sanitize_motion(text)
  end

  def sanitize_motion(text)
    ActionController::Base.helpers.sanitize(text, tags: %w(a b i p ol ul li blockquote br em sup sub dl dt dd), attributes: %w(href class pwmotiontext))
  end
end

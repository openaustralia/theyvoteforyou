# frozen_string_literal: true

module DivisionSummaryPipeline
  # The Type 1 facts about a division (ARCHITECTURE.md, Data classification): chamber, date,
  # time, counts, bills, result. They come from the TVFY database and nowhere else, never from
  # Hansard text and never from the model, and every stage reads them from here.
  #
  # Built from a Division record, or from a plain Hash so the evaluation fixtures and specs can
  # drive the pipeline without the database. A Hash may also carry `supplied` facts TVFY does
  # not record but a caller knows (a Bills Digest, a bill's originating chamber, a follow-up
  # division link, the mover), which ARCHITECTURE.md section 15 lists as integration seams.
  # bill_titles is every bill's own title, as the bills table records it; bill_name is the one a
  # summary names, the first bill's with a count of the others.
  DivisionFacts = Data.define(
    :id, :house, :date, :number, :clock_time, :name, :debate_gid,
    :aye_votes, :no_votes, :turnout, :rebellions, :bill_name, :bill_link, :bill_titles,
    :amount, :result, :tied, :free_vote, :supplied
  )

  class DivisionFacts
    # Result spellings a Hash may use for a question that was agreed to.
    AGREED_RESULTS = ["passed", "agreed to", "for", "yes", "successful", "carried"].freeze

    def self.from(division)
      division.is_a?(Hash) ? from_hash(division) : from_record(division)
    end

    def self.from_hash(data)
      facts = data.to_h.transform_keys(&:to_sym)
      aye_votes = facts[:aye_votes].to_i
      no_votes = facts[:no_votes].to_i
      turnout = facts[:turnout].to_i
      turnout = aye_votes + no_votes if turnout.zero?
      known = members.map(&:to_sym) - %i[supplied]

      new(
        id: facts[:id], house: facts[:house].to_s.presence || "representatives", date: facts[:date].to_s,
        number: facts[:number].to_i, clock_time: facts[:time].presence || facts[:clock_time].to_s,
        name: facts[:name].to_s, debate_gid: facts[:debate_gid].to_s,
        aye_votes: aye_votes, no_votes: no_votes, turnout: turnout, rebellions: facts[:rebellions] || 0,
        bill_name: facts[:bill_name].presence, bill_link: facts[:bill_link].to_s,
        bill_titles: Array(facts[:bill_titles]).presence || [facts[:bill_name].presence].compact,
        amount: facts[:amount].presence, result: facts[:result].to_s.downcase,
        tied: facts[:tied] || (turnout.positive? && aye_votes == no_votes),
        free_vote: facts[:free_vote] || false,
        supplied: facts.except(*known, :time)
      )
    end

    def self.from_record(division)
      bills = division.bills.to_a
      aye_votes = division.aye_votes_including_tells.to_i
      no_votes = division.no_votes_including_tells.to_i
      turnout = division.division_info&.turnout.to_i
      turnout = aye_votes + no_votes if turnout.zero?

      new(
        id: division.id, house: division.house.to_s, date: division.date.to_s, number: division.number.to_i,
        clock_time: division.clock_time.to_s, name: division.name.to_s, debate_gid: division.debate_gid.to_s,
        aye_votes: aye_votes, no_votes: no_votes, turnout: turnout, rebellions: division.rebellions || 0,
        bill_name: bill_title(bills), bill_link: bills.first&.url.to_s, bill_titles: bills.map(&:title).compact,
        amount: majority_strength(division.division_info&.majority_fraction),
        result: division.passed? ? "passed" : "negatived", tied: division.tied?,
        free_vote: division.whips.any?(&:free_vote?), supplied: {}
      )
    end

    def self.bill_title(bills)
      return nil if bills.empty?
      return bills.first.title if bills.size == 1

      others = bills.size - 1
      "#{bills.first.title} (and #{others} related #{others == 1 ? 'bill' : 'bills'})"
    end

    # The division page's own words for how big the majority was, with its thresholds
    # (DivisionsHelper#majority_strength_in_words), so a draft never calls a majority "large"
    # that the page beside it calls "modest". The helper builds HTML, so the thresholds are
    # repeated here rather than called; if they change there they must change here.
    def self.majority_strength(fraction)
      return "majority" if fraction.nil?
      return "large majority" if fraction > 2.0 / 3
      return "modest majority" if fraction > 1.0 / 3
      return "small majority" if fraction.positive?

      "majority"
    end

    def senate?
      house.downcase.include?("senate")
    end

    def chamber
      senate? ? "Senate" : "House of Representatives"
    end

    def other_chamber
      senate? ? "House of Representatives" : "Senate"
    end

    # The loader's spelling ("representatives" or "senate"), which Member.house uses.
    def house_key
      House.australian.find { |key| house.downcase.include?(key) }
    end

    def time
      ClockTime.display(clock_time)
    end

    def agreed?
      AGREED_RESULTS.include?(result)
    end

    # How many members the chamber had on the day, from TVFY's own member records (KI-8), or
    # nil when that is not known, in which case callers fall back to the guides' figures.
    def member_count
      supplied_size = supplied[:chamber_size].to_i
      return supplied_size if supplied_size.positive?
      return nil if house_key.blank? || date.blank?

      count = Member.in_house(house_key).current_on(date).count
      count.positive? ? count : nil
    rescue StandardError
      nil
    end

    def [](key)
      supplied[key.to_sym]
    end
  end
end

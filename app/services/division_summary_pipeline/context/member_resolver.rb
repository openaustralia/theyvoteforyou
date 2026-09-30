# frozen_string_literal: true

module DivisionSummaryPipeline
  # ResolvedMember carries the TVFY database facts for a politician a template wants to
  # name: their canonical name, party, electorate and profile path. Every attribute other
  # than member is nil when the database has no match, so callers can fall back to plain
  # text rather than publishing broken links or guessed details.
  ResolvedMember = Struct.new(:member, :name, :party, :electorate, :link, keyword_init: true)

  # MemberResolver turns a name or electorate extracted from Hansard into authoritative
  # TVFY member facts, for the templates that must name a second person (who a censure
  # motion targets, which member was ruled no longer heard).
  #
  # The extraction never supplies parties, electorates or profile
  # links (ARCHITECTURE.md, Data classification section: member details are Type 1
  # facts with zero AI involvement); it only reports what the Hansard text states, and
  # this class asks the database for the rest. Scoping by the division's house and date
  # keeps historical divisions pointing at the member who actually held the seat then,
  # not whoever holds it today.
  class MemberResolver
    include Rails.application.routes.url_helpers

    def self.resolve(name: nil, electorate: nil, house: nil, date: nil, gid: nil)
      new.resolve(name: name, electorate: electorate, house: house, date: date, gid: gid)
    end

    HONORIFICS = /\b(mr|mrs|ms|miss|dr|senator|representative|member|hon|honourable|mp)\b/i

    # Whether two ways of writing a member's name mean the same person: "Senator Whitten" and
    # "Tyron Whitten", or "Hodgins-May" and "Steph Hodgins-May". Compared word by word, never as
    # substrings, because "rae" is inside "graeme" and a substring match once credited one
    # member's words to another. A surname alone matches a full name; two full names must agree
    # on the first name too.
    def self.same_speaker?(one, other)
      a = name_words(one)
      b = name_words(other)
      return false if a.empty? || b.empty?
      return true if (a - b).empty? || (b - a).empty?

      a.last == b.last && (a.size == 1 || b.size == 1 || a.first == b.first)
    end

    def self.name_words(name)
      TextNormaliser.normalise_for_matching(name).gsub(HONORIFICS, " ").gsub(/\[.*?\]/, " ")
                    .gsub(/[^\w\s]/, " ").split
    end

    # A member known only by the name Hansard printed, with no database record behind it, so no
    # party, electorate or link can be given. Built here so callers need not reach for
    # ResolvedMember directly, which lives in this file and so cannot be autoloaded on its own.
    def self.named(name)
      ResolvedMember.new(member: nil, name: name.presence, party: nil, electorate: nil, link: nil)
    end

    # The member Hansard names by title and surname alone ("Senator McKim"), when exactly one member
    # of the house on the day has that surname: the Senate has had two Pococks at once, so a
    # surname is not assumed to be unique.
    def self.by_surname(surname, house:, date:)
      scope = Member.where(last_name: surname.to_s.strip)
      scope = scope.in_house(house) if house.present?
      scope = scope.current_on(date) if date.present?
      members = scope.to_a
      members.one? ? resolve(gid: members.first.gid) : named(surname)
    end

    # gid is the Hansard speaker id ("uk.org.publicwhip/member/123"), which identifies a member
    # stint exactly, so it is tried before any name or electorate.
    def resolve(name: nil, electorate: nil, house: nil, date: nil, gid: nil)
      member = (Member.find_by(gid: gid) if gid.present?) ||
               find_member(name: name, electorate: electorate, house: house, date: date)
      return ResolvedMember.new(member: nil, name: nil, party: nil, electorate: nil, link: nil) unless member

      ResolvedMember.new(
        member: member,
        name: member.name,
        party: member.party_name,
        electorate: member.senator? ? nil : member.electorate,
        link: member_path(member.url_params)
      )
    end

    private

    # Name before electorate, since Hansard states a name less ambiguously than a seat, and
    # the most recent matching stint when a person held several.
    def find_member(name:, electorate:, house:, date:)
      scope = Member.all
      scope = scope.in_house(house) if house.present?
      scope = scope.current_on(date) if date.present?
      if name.present?
        scope.with_name(name).order(entered_house: :desc).first
      elsif electorate.present?
        scope.where(constituency: electorate).order(entered_house: :desc).first
      end
    end
  end
end

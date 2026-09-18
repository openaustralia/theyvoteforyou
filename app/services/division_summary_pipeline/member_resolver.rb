# frozen_string_literal: true

module DivisionSummaryPipeline
  # ResolvedMember carries the TVFY database facts for a politician a template wants to
  # name: their canonical name, party, electorate and profile path. Every attribute other
  # than member is nil when the database has no match, so callers can fall back to plain
  # text rather than publishing broken links or guessed details.
  ResolvedMember = Struct.new(:member, :name, :party, :electorate, :link, keyword_init: true)

  # MemberResolver turns a name or electorate extracted from Hansard into authoritative
  # TVFY member facts. The extraction never supplies parties, electorates or profile
  # links (ARCHITECTURE.md, Data classification section: member details are Type 1
  # facts with zero AI involvement); it only reports what the Hansard text states, and
  # this class asks the database for the rest. Scoping by the division's house and date
  # keeps historical divisions pointing at the member who actually held the seat then,
  # not whoever holds it today.
  class MemberResolver
    include Rails.application.routes.url_helpers

    def self.resolve(name: nil, electorate: nil, house: nil, date: nil)
      new.resolve(name: name, electorate: electorate, house: house, date: date)
    end

    def resolve(name: nil, electorate: nil, house: nil, date: nil)
      member = find_member(name: name, electorate: electorate, house: house, date: date)
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

# frozen_string_literal: true

module DivisionSummaryPipeline
  # ResolvedMember carries the TVFY database facts for a politician a template wants to
  # name: their canonical name, party, electorate and profile path. Every attribute other
  # than member is nil when the database has no match, so callers can fall back to plain
  # text rather than publishing broken links or guessed details.
  ResolvedMember = Struct.new(:member, :name, :party, :electorate, :link, keyword_init: true)
end

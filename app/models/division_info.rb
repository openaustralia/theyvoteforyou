# frozen_string_literal: true

class DivisionInfo < ApplicationRecord
  belongs_to :division

  # TODO: Fix duplication between this class and MemberInfo

  def majority
    aye_majority.abs
  end

  # a tie is 0.0. a unanimous vote is 1.0
  def majority_fraction
    turnout.positive? ? majority.to_f / turnout : 0
  end

  def self.update_all!
    update_divisions!(nil)
  end

  # Rebuild the cache for just these divisions, or for all of them when given
  # nil. Whips must already exist for them, otherwise the rebellion counts come
  # back empty - Vote.rebellious inner joins whips.
  def self.update_divisions!(division_ids)
    division_ids = Array(division_ids) if division_ids
    return if division_ids && division_ids.empty?

    rebellions = all_rebellion_counts(division_ids)
    tells = all_tells_counts(division_ids)
    turnout = all_turnout_counts(division_ids)
    possible_turnout = all_possible_turnout_counts(division_ids)
    aye_majority = all_aye_majority_counts(division_ids)

    # Divisions with no votes at all are missing from every aggregate above, but
    # still need a row of zeroes, so drive the loop from the ids not the counts.
    (division_ids || Division.ids).each do |id|
      info = DivisionInfo.find_or_initialize_by(division_id: id)
      info.update!(rebellions: rebellions[id] || 0, tells: tells[id] || 0,
                   turnout: turnout[id] || 0, possible_turnout: possible_turnout[id] || 0,
                   aye_majority: aye_majority[id] || 0)
    end
  end

  def self.all_rebellion_counts(division_ids = nil)
    for_divisions(Vote.rebellious, division_ids).group("votes.division_id").count
  end

  def self.all_tells_counts(division_ids = nil)
    for_divisions(Vote.tells, division_ids).group("votes.division_id").count
  end

  def self.all_turnout_counts(division_ids = nil)
    for_divisions(Vote.all, division_ids).group("votes.division_id").count
  end

  def self.all_ayes_counts(division_ids = nil)
    for_divisions(Vote.ayes, division_ids).group("votes.division_id").count
  end

  def self.all_noes_counts(division_ids = nil)
    for_divisions(Vote.noes, division_ids).group("votes.division_id").count
  end

  def self.all_aye_majority_counts(division_ids = nil)
    ayes = all_ayes_counts(division_ids)
    noes = all_noes_counts(division_ids)
    keys = (ayes.keys + noes.keys).uniq
    r = {}
    keys.each do |key|
      r[key] = (ayes[key] || 0) - (noes[key] || 0)
    end
    r
  end

  def self.all_possible_turnout_counts(division_ids = nil)
    scope = Division.joins("INNER JOIN members ON divisions.house = members.house AND members.entered_house <= divisions.date AND divisions.date < members.left_house")
    scope = scope.where(divisions: { id: division_ids }) if division_ids
    scope.group("divisions.id").count
  end

  # Only narrow the scope when we've been given divisions to narrow it to, so
  # that a full rebuild doesn't pay for a redundant WHERE over every division.
  def self.for_divisions(scope, division_ids)
    division_ids ? scope.where(votes: { division_id: division_ids }) : scope
  end
  private_class_method :for_divisions
end

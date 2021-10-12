# frozen_string_literal: true

class Person < ApplicationRecord
  has_many :members, -> { order(entered_house: :desc) }
  has_many :policy_person_distances
  has_many :offices
  # People who are currently in parliament
  scope :current, -> { joins(:members).merge(Member.current) }

  # Total number of rebellions across all members for this person
  def rebellions
    members.to_a.sum { |m| m.rebellions.to_i }
  end

  # total number of free votes across all members for the person
  # while they were a member of a party with a whip
  def free_votes_with_whip
    members.to_a.sum { |m| m.has_whip? ? m.free_divisions.size : 0 }
  end

  # Total number of votes across all members for this person
  def votes_attended
    members.to_a.sum { |m| m.votes_attended.to_i }
  end

  # Total number of votes they could have attended across all members for this person
  def votes_possible
    members.to_a.sum { |m| m.votes_possible.to_i }
  end

  # The total number of votes that this person attended while they were a member of
  # a party with a whip
  def votes_attended_with_whip
    members.to_a.sum { |m| m.has_whip? ? m.votes_attended.to_i : 0 }
  end

  # True if this person has been a member of a party with a whip
  def has_whip?
    members.any? { |m| m.has_whip? }
  end

  # Returns a number between 0 and 1 or nil
  def rebellions_fraction
    rebellions.to_f / votes_attended if votes_attended_with_whip > 0
  end

  # Returns a number between 0 and 1 or nil
  def attendance_fraction
    votes_attended.to_f / votes_possible if votes_possible > 0
  end

  def show_large_image?
    !!large_image_url
  end

  def show_small_image?
    !!small_image_url
  end

  def latest_member
    members.first
  end

  def earliest_member
    members.last
  end

  def member_who_voted_on_division(division)
    # What we have now in @member is a member related to the person that voted in division but @member wasn't necessarily
    # current when @division took place. So, let's fix this
    # We're doing this the same way as the php which doesn't seem necessarily the best way
    # TODO Figure what is the best way
    new_member = members.find do |member|
      member.vote_on_division_without_tell(division) != "absent"
    end
    new_member || latest_member
  end

  # Find the member that relates to a given policy
  # Let's just step through the votes of the policy and find the first matching member
  def member_for_policy(policy)
    policy.divisions.each do |division|
      member = members.current_on(division.date).first
      return member if member
    end
    # If we can't find a member just return the first one
    latest_member
  end

  def agreement_fraction_with_policy(policy)
    pmd = policy_person_distances.find_by(policy: policy)
    pmd ? pmd.agreement_fraction : 0
  end

  def number_of_votes_on_policy(policy)
    pmd = policy_person_distances.find_by(policy: policy)
    pmd ? pmd.number_of_votes : 0
  end

  def current_offices
    # Checking for the to_date after the sql query to get the same result as php
    offices.order(from_date: :desc).select { |o| o.to_date == Date.new(9999, 12, 31) }
  end

  def offices_on_date(date)
    offices.where("? >= from_date AND ? <= to_date", date, date)
  end

  # TODO: This is wrong as parliamentary secretaries will be considered to be on the
  # front bench which as far as I understand is not the case
  def on_front_bench?(date)
    !offices_on_date(date).empty?
  end
end

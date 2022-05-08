# frozen_string_literal: true

class Person < ApplicationRecord
  has_many :members, -> { order(entered_house: :desc) }, inverse_of: :person, dependent: :destroy
  has_many :policy_person_distances, dependent: :destroy
  has_many :offices, dependent: :destroy
  has_many :people_distances, foreign_key: :person1_id, dependent: :destroy, inverse_of: :person1

  # People who are currently in parliament
  scope :current, -> { joins(:members).merge(Member.current) }

  delegate :name, :first_name, :last_name, :full_name, :currently_in_parliament?, :party_name, :role, to: :latest_member

  # Total number of rebellions across all members for this person
  def rebellions
    members.to_a.sum { |m| m.rebellions.to_i }
  end

  # total number of free votes across all members for the person
  # while they were a member of a party with a whip
  def free_votes_with_whip
    members.to_a.sum { |m| m.subject_to_whip? ? m.free_divisions.size : 0 }
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
    members.to_a.sum { |m| m.subject_to_whip? ? m.votes_attended.to_i : 0 }
  end

  # True if this person has been a member of a party with a whip
  def subject_to_whip?
    members.any?(&:subject_to_whip?)
  end

  # Returns a number between 0 and 1 or nil
  def rebellions_fraction
    rebellions.to_f / votes_attended if votes_attended_with_whip.positive?
  end

  # Returns a number between 0 and 1 or nil
  def attendance_fraction
    votes_attended.to_f / votes_possible if votes_possible.positive?
  end

  def show_extra_large_image?
    !!extra_large_image_url
  end

  def show_large_image?
    !!large_image_url
  end

  def show_small_image?
    !!small_image_url
  end

  # These are images sizes only used on the social cards
  def extra_large_image_width
    150
  end

  def extra_large_image_height
    200
  end

  # Currently hardcoded to the image sizes that openaustralia.org.au uses
  # Matches sizes set in https://github.com/openaustralia/openaustralia-parser/blob/master/lib/people_image_downloader.rb#L13
  def large_image_width
    88
  end

  def large_image_height
    118
  end

  def small_image_width
    44
  end

  def small_image_height
    59
  end

  def extra_large_image_size
    "#{extra_large_image_width}x#{extra_large_image_height}"
  end

  def large_image_size
    "#{large_image_width}x#{large_image_height}"
  end

  def small_image_size
    "#{small_image_width}x#{small_image_height}"
  end

  def latest_member
    members.first
  end

  def earliest_member
    members.last
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

  def current_offices
    # Checking for the to_date after the sql query to get the same result as php
    offices.order(from_date: :desc).select { |o| o.to_date == Date.new(9999, 12, 31) }
  end

  def offices_on_date(date)
    offices.where("? >= from_date AND ? <= to_date", date, date)
  end

  # Was this person a member of parliament in the right house on the day of the division?
  def could_have_voted_in_division?(division)
    !member_in_division(division).nil?
  end

  def member_in_division(division)
    members.current_on(division.date).find_by(house: division.house)
  end

  def vote_on_division_without_tell(division)
    member = member_in_division(division)
    if member
      member.vote_on_division_without_tell(division)
    else
      # If person could not have attended the division
      "-"
    end
  end

  # People who were in parliament (in the same house) at the same time
  # Note that this also includes themselves
  def overlapping_people
    members.map { |member| member.overlapping_members.to_a }.flatten
           .uniq.map(&:person).uniq
  end

  def possible_friends
    people_distances.where.not(person2_id: id).where.not(distance_b: -1)
  end

  # Friends who have voted exactly the same
  def best_friends
    possible_friends.where(distance_b: 0)
  end
end

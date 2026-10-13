# frozen_string_literal: true

class Policy < ApplicationRecord
  searchkick index_name: "tvfy_policies_#{Rails.env}"
  # Using proc form of meta so that policy_id is set on create as well
  # See https://github.com/airblade/paper_trail/issues/185#issuecomment-11781496 for more details
  has_paper_trail meta: { policy_id: proc(&:id) }
  has_many :policy_divisions, dependent: :destroy
  has_many :divisions, through: :policy_divisions
  has_many :ai_policy_suggestions, dependent: :nullify
  has_many :policy_person_distances, dependent: :destroy
  has_many :watches, as: :watchable, dependent: :destroy, inverse_of: :watchable
  belongs_to :user

  validates :name, :description, :private, presence: true
  validates :name, uniqueness: { case_sensitive: false }, length: { maximum: 100 }

  # TODO: Remove "legacy Dream MP"
  enum :private, { published: 0, "legacy Dream MP": 1, provisional: 2 }
  # TODO: Rename field in schema
  alias_attribute :status, :private

  def name_with_for
    "for #{name}"
  end

  def vote_for_division(division)
    policy_division = division.policy_divisions.find_by(policy: self)
    policy_division&.vote
  end

  # Loads the figures shown on each row of a policy list with a fixed number of grouped queries, rather than several
  # queries per policy. Returns the policies as an array. Methods below use the batched figures when present and
  # otherwise query for them, so policies loaded any other way behave as before.
  def self.with_list_stats(policies)
    policies = policies.to_a
    ids = policies.map(&:id)
    division_counts = Division.joins(:policy_divisions).where(policy_divisions: { policy_id: ids })
    # Grouped queries leave out policies with a count of zero, so default missing counts to zero
    stats = {
      divisions_count: Hash.new(0).merge(division_counts.group("policy_divisions.policy_id").count),
      unedited_motions_count: Hash.new(0).merge(division_counts.unedited.group("policy_divisions.policy_id").count),
      last_version_at: PaperTrail::Version.where(policy_id: ids).group(:policy_id).maximum(:created_at),
      watches_count: Hash.new(0).merge(Watch.where(watchable_type: "Policy", watchable_id: ids)
                                            .group(:watchable_id).count)
    }
    policies.each { |policy| policy.list_stats = stats }
  end

  attr_writer :list_stats

  def divisions_count
    list_stat(:divisions_count) || divisions.count
  end

  def unedited_motions_count
    list_stat(:unedited_motions_count) || divisions.unedited.count
  end

  def watches_count
    list_stat(:watches_count) || watches.count
  end

  # Note that this includes changes to policy record and policy_division records
  def most_recent_version
    PaperTrail::Version.order(created_at: :desc).find_by(policy_id: id)
  end

  # TODO: It would be great if we could just use updated_at instead but this would require some additions of "touch"
  def last_edited_at
    last_version_at = @list_stats ? @list_stats[:last_version_at][id] : most_recent_version&.created_at
    last_version_at || updated_at
  end

  # Returns nil if the user who made this edit has since been deleted. Only a policy's owner is
  # protected from deletion (User#policies is dependent: :restrict_with_exception); a user who
  # merely edited someone else's policy isn't, so their account can still be removed later.
  def last_edited_by
    User.find_by(id: most_recent_version.whodunnit)
  end

  def members_who_could_have_voted_on_this_policy
    member_ids = []
    divisions.each do |division|
      member_ids += division.members_who_could_have_voted.pluck(:id)
    end
    member_ids.uniq.map { |id| Member.find(id) }
  end

  def people_who_could_have_voted_on_this_policy
    members_who_could_have_voted_on_this_policy.map(&:person_id).uniq.map { |id| Person.find(id) }
  end

  def calculate_person_distances!
    people = people_who_could_have_voted_on_this_policy

    # Delete records that shouldn't be there anymore and won't be update further below
    policy_person_distances.where(PolicyPersonDistance.arel_table[:person_id].not_in(people.map(&:id))).delete_all

    # Step through all the people that could have voted on this policy
    people.each do |person|
      policy_person_distances.find_or_initialize_by(person_id: person.id).update_distance!
    end
  end

  def alert_watches(version)
    AlertWatchesJob.perform_later(self, version)
  end

  private

  def list_stat(key)
    @list_stats&.dig(key, id)
  end
end

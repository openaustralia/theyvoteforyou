# frozen_string_literal: true

class AddTimestampsToAllTables < ActiveRecord::Migration
  def change
    add_timestamps :division_infos
    add_timestamps :divisions
    add_timestamps :electorates
    add_timestamps :member_distances
    add_timestamps :member_infos
    add_timestamps :members
    add_timestamps :offices
    add_timestamps :policies
    add_timestamps :policy_divisions
    add_timestamps :policy_person_distances
    add_timestamps :users
    add_timestamps :votes
    add_timestamps :whips
    add_timestamps :wiki_motions
  end
end

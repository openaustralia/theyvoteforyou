# frozen_string_literal: true

class RenameMpIdsInMemberDistances < ActiveRecord::Migration
  def change
    rename_column :member_distances, :mp_id1, :member1_id
    rename_column :member_distances, :mp_id2, :member2_id
  end
end

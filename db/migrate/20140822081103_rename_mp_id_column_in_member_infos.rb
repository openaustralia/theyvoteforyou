# frozen_string_literal: true

class RenameMpIdColumnInMemberInfos < ActiveRecord::Migration
  def change
    rename_column :member_infos, :mp_id, :member_id
  end
end

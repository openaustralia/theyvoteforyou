class DropMemberDistances < ActiveRecord::Migration[6.0]
  def change
    drop_table :member_distances do |t|
      t.integer  :member1_id, null: false
      t.integer  :member2_id, null: false
      t.integer  :nvotessame
      t.integer  :nvotesdiffer
      t.integer  :nvotesabsent
      t.float    :distance_a, limit: 24
      t.float    :distance_b, limit: 24
      t.datetime :created_at
      t.datetime :updated_at
      t.index [:member1_id, :member2_id], name: "mp_id1_2", unique: true, using: :btree
      t.index [:member1_id], name: "mp_id1", using: :btree
      t.index [:member2_id], name: "mp_id2", using: :btree
    end
  end
end

class CreatePeopleDistances < ActiveRecord::Migration[6.0]
  def change
    create_table :people_distances do |t|
      t.integer :person1_id, null: false
      t.integer :person2_id, null: false
      t.integer :nvotessame, null: false
      t.integer :nvotesdiffer, null: false
      t.float :distance_b, null: false
      t.timestamps

      t.index :person1_id
      t.index :person2_id
      t.index [:person1_id, :person2_id], unique: true
    end
  end
end

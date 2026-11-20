# frozen_string_literal: true

# Records whether Parliament had published the final Hansard when we loaded a division's day.
# proof is deliberately nullable: existing rows stay null (unknown) until their day is reloaded.
class AddProofToDivisions < ActiveRecord::Migration[8.0]
  def change
    add_column :divisions, :proof, :boolean
  end
end
